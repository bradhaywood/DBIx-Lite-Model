package DBIx::Lite::Model;

our $VERSION = '0.001';

use Mouse;
use YAML::Syck;
extends 'DBIx::Lite';

has '_config' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub config {
    my ($class, $file) = @_;
    $class->_config( LoadFile($file) ) if -f $file;
    return $class;
}

sub model {
    my ($class, $model) = @_;
    my $dbh;
    my $table;
    my $result;
    my $yaml = $class->_config;
    if (! grep { $_ eq $model } keys %$yaml) {
        warn "Could not find model: $model";
        return 0;
    }
    else {
        if ($yaml->{$model}->{model}) {
            my $use_model = $yaml->{$model}->{model};
            $dbh = $class->connect(
                'dbi:' . $yaml->{$use_model}->{connect},
                $yaml->{$use_model}->{user}||undef,
                $yaml->{$use_model}->{pass}||undef,
            );
        }
        else {
            $dbh = $class->connect(
                'dbi:' . $yaml->{$model}->{connect},
                $yaml->{$model}->{user}||undef,
                $yaml->{$model}->{pass}||undef,
            );
        }

        if ($yaml->{$model}->{related}) {
            if ($yaml->{$model}->{related} =~ /^(\w+)\s*?<\->\s*?(\w+)\s*?\(\s*?(\w+)\s*?\)$/) {
                my $relate_table = $2;
                my $relation_id = $1;
                my $related_id = $3;
                $dbh->schema->one_to_many("${relation_id}.$yaml->{$model}->{primary_key}" => "${relate_table}.${related_id}");
            }
        }

        if ($yaml->{$model}->{primary_key}) {
            if ($table = $yaml->{$model}->{table}) {
                $dbh->schema->table($table)->autopk($yaml->{$model}->{primary_key});
            }
            else {
                warn "You should probably have a table defined in the model if you're going to supply a primary key";
                return 0;
            }
        }
        
        if ($yaml->{$model}->{table}) {
            $dbh = $dbh->table($yaml->{$model}->{table});
        }

        if ($yaml->{$model}->{columns}) {
            $dbh = $dbh->select(@{$yaml->{$model}->{columns}});
        }
        
    }

    return $result if $result;
    return $dbh if $dbh;
}

=head1 NAME

DBIx::Lite::Model - Centralise DBIx::Lite models in YAML

=head1 DESCRIPTION

This module is a subclass of L<DBIx::Lite>. It allows you to centralise your model configuration in yaml files for easy reusability.

=head1 SYNOPSIS

Create a yaml file. You may wish to have one model have the connection information, then you can create other models within that yaml file which use that model for their connection. An example is below.

    # mydb.yml
    MyDB:
        connect: Pg:dbname=some_db
        user: foo_user
        pass: foo_pass
    
    Client:
        model: MyDB
        table: clients
        primary_key: id
    
    Customer:
        model: EcmDB
        table: customers
        primary_key: id
        related: clients <-> customers(client_id)

This allows us to do stuff like

    # test.pl
    use DBIx::Lite::Model;
    
    my $dbix = DBIx::Lite::Model->new;  # Creates a new instance
    $dbix->config('mydb.yml');          # load the configuration

    my $customer_rs = $dbix->model('Customer'); # Returns the Customer ResultSet
    my $client_rs   = $dbix->model('Client');   # Returns the Client ResultSet

    # we want to find out what customers client with id 5 has
    my $customers = $client_rs->find(5)->customers;
    $customers->single->name; # returns the name of the clients first customer

=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

Allessandro Ranellucci is the author of L<DBIx::Lite>

=head1 SEE ALSO

L<DBIx::Lite>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
