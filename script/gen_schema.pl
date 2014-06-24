#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Config::General;
use FindBin;
use lib "$FindBin::Bin/../lib";
use DanceParty::Schema;

my ( $preversion, $help );
GetOptions(
        'p|preversion:s'  => \$preversion,
    ) or die pod2usage;

my $conf = new Config::General('danceparty.conf');
my %config = $conf->getall;
my $connect_info = $config{'Model::DB'}{'connect_info'};
my $schema = DanceParty::Schema->connect(@$connect_info);

my $version = $schema->schema_version();

if ($version && $preversion) {
    print "creating diff between version $version and $preversion\n";
} elsif ($version && !$preversion) {
    print "creating full dump for version $version\n";
} elsif (!$version) {
    print "creating unversioned full dump\n";
}

my $sql_dir = './sql';
#$schema->create_ddl_dir( 'PostgreSQL', $version, $sql_dir, $preversion );
$schema->create_ddl_dir( ['MySQL', 'PostgreSQL'], $version, $sql_dir, $preversion );
