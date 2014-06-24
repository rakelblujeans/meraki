#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use DanceParty::Schema;
use Config::General;

my %config = new Config::General('danceparty.conf')->getall;
my $connect_info = $config{'Model::DB'}{'connect_info'};
my $schema = DanceParty::Schema->connect(@$connect_info);

if (!$schema->get_db_version()) {
    # schema is unversioned
    print "Schema is unversioned. Deploying...\n";
    $schema->deploy();
} else {
    print "Upgrading schema...\n";
    $schema->upgrade();
}

print "Done!\n";
