#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use DanceParty::Schema;
use Data::Dumper::Concise;
use Config::General;

my %config = new Config::General('danceparty.conf')->getall;
my $connect_info = $config{'Model::DB'}{'connect_info'};
my $schema = DanceParty::Schema->connect(@$connect_info);

my $now = DateTime->now;
my @location_types = (
    ['club', $now],
    ['bar/lounge', $now],
    ['park/outdoors', $now],
    ['rooftop', $now],
    ['warehouse', $now],
    ['beach/boat/water front', $now],
    ['house party', $now],
    ['restaurant', $now],
    ['secret location', $now],
    ['other', $now],
    ['unlabeled', $now],
    );
my $found = $schema->resultset('LocationType')->search({ location_type => 'club'},{ rows => 1 })->single;
unless ($found) {
    $schema->populate('LocationType', [ [qw/location_type created_at/], @location_types ]);
}

my @roles = (['regular_user'], ['admin'], ['promoter']);
$found = $schema->resultset('Role')->search({ role_name => 'regular_user' }, { rows => 1 })->single;
unless ($found) {
    $schema->populate('Role', [ [qw/role_name/], @roles]);
}
