#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Config::General;
use LWP::UserAgent;
use DateTime::Format::Strptime;
use Data::Dumper::Concise;
use JSON::XS;

BEGIN {
#    use_ok 'DanceParty';
    use_ok 'DanceParty::Schema';
    use_ok 'DanceParty::Model::Facebook';
}

#my $now = DateTime->now->set_time_zone( 'America/New_York' );

my %config = new Config::General('danceparty.conf')->getall;

my $connect_info = $config{'Model::DB'}{'connect_info'};
my $schema = DanceParty::Schema->connect(@$connect_info);
ok($schema, "Got schema");

sub setup_event {
    my $name = 'test_event';
    my $event = $schema->resultset('Event')->find(
	{ name => $name });
    $event->delete() if $event;

    my $now = DateTime->now->set_time_zone( 'America/New_York' );
    $event = $schema->resultset('Event')->create(
	{ name           => $name,
	  organizer_name => "test_organizer",
#	  email          => "rsvp\@organizer.net",
	  music_genre    => "test_genre",
	  artists        => "test_artists",
	  start_time     => $now,
#	  more_info      => "http://www.hahaha.com",
#	  youtube_url    => "http://www.ticketmaster.com",
#	  tickets_url    => "http://www.ticketmaster.com",
#	  ticket_price   => "Free",
#	  additional_description => "blah blah and more blah",
	  privacy        => "OPEN",
	  active         => 1,
	  location_id    => $loc->location_id,
	  created_at     => $now,
	});
    return $event;
}

sub create_event {
    my $new_event = $schema->resultset('Event')->create_event($fif, $user);
    ok($new_event, "created new event in our db");
}

sub create_bad_event {

}

sub update_event {
    my $event = setup_event();
    $event->youtube_url = "http://www.ticketmaster.com";
    my $updated_event = $schema->resultset('Event')->update_event($fif, $id);
    ok($updated_event->youtube_url, "http://www.ticketmaster.com", "updated event");
}

sub update_bad_event {

}

done_testing();
