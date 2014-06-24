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
    
my $user_rs = $schema->resultset('UserAccount');

for(my $i=0; $i<3; $i++) {
    $schema->resultset('UserAccount')->create({
	email => "test_user" . $i,  #."\@danceparty.com",
	username => "test_user" . $i,
	password => "kermitLovesYou",
	city => 'New York',
	active => 1 });
}

