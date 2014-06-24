#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use DateTime::Format::Strptime;
use Data::Dumper::Concise;
use LWP::UserAgent;
use JSON::XS;

my $now = DateTime->now;
my $google_url = 'https://maps.googleapis.com/maps/api/timezone/json?' .
    'location=40.7200037,-73.9881268' .
    '&timestamp=' . $now->epoch .
    '&sensor=false';

warn "\nURL: " . $google_url . "\n";
my $ua = new LWP::UserAgent;
my $response = $ua->get($google_url);
my $content = $response->content;
my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
my $timezone_info = $coder->decode($content);
warn "\n\nTIMEZONE INFO:\n" . Dumper $timezone_info;
ok($timezone_info);

#$now->set_time_zone('Australia/Sydney');
warn "\n TIME: $now \n";

done_testing();
