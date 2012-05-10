use inc::Module::Install;

name     'DBIx-Lite-Model';
all_from 'lib/DBIx/Lite/Model.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'perl';

build_requires 'Test::More';
requires 'Mouse';
requires 'YAML::Syck';

auto_install;

WriteAll;

