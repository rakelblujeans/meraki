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

my $now = DateTime->now->set_time_zone( 'America/New_York' );

my %config = new Config::General('danceparty.conf')->getall;

my $connect_info = $config{'Model::DB'}{'connect_info'};
my $schema = DanceParty::Schema->connect(@$connect_info);
ok($schema, "Got schema");

# send data to facebook
my $fb = Facebook->new( schema => $schema,
			app_id => $config{'Facebook'}{'app_id'},
			secret => $config{'Facebook'}{'secret'} );

ok($fb, "Created facebook model");

my $app_token = $fb->get_app_access_token();
ok($app_token, "Got app token");

my $ids = $fb->delete_all_test_users($app_token);
ok($ids, "Deleted all test users in fb");
# TODO: add additional db tests to verify changes went through correctly

my $fbuser1 = $fb->create_test_user($app_token);
ok($fbuser1, "Created test user1");

my $fbuser2 = $fb->create_test_user($app_token);
ok($fbuser2, "Created test user2");

my $success = $fb->delete_user($fbuser1->fbtestuser_id);
is($success, 1, "Deleted test user1");

my $loc = $schema->resultset('Location')->first;
my $fbloc = $fb->add_fblocation($fbuser2, $loc);
ok($fbloc, 'Got place info from facebook');

my $new_event = setup_event();
ok($new_event, "created new event in our db");
my $fb_event = $fb->post_event($fbuser2, $new_event, $fbloc);
ok($fb_event, "Posted event to fb");

$now = DateTime->now->set_time_zone( 'America/New_York' );
my $now_str = $now->datetime . $now->strftime('%z');
my $args = { name         => 'updated event name!',
	     start_time   => $now_str,
	     #description  => 'update that description!',
	     #privacy_type => 'SECRET',
};
$success = $fb->edit_event($fbuser2, $fb_event->fb_id, $args);
ok($success, "Updated event");

$success = $fb->delete_event($fb_event->fb_id, $fbuser2);
ok($success, "Deleted event");

done_testing();

sub setup_event {
    my $event = $schema->resultset('Event')->find(
	{ name => 'test_event' });
    $event->delete() if $event;
    $event = $schema->resultset('Event')->find(
	{ name => 'updated event name!' });
    $event->delete() if $event;

    $event = $schema->resultset('Event')->create(
	{ name     => "test_event",
	  organizer_name => "test_organizer",
	  email          => "rsvp\@organizer.net",
	  music_genre    => "test_genre",
	  artists        => "test_artists",
	  start_time     => $now,
	  more_info      => "http://www.hahaha.com",
	  youtube_url    => "http://www.ticketmaster.com",
	  tickets_url    => "http://www.ticketmaster.com",
	  ticket_price   => "Free",
	  additional_description => "blah blah and more blah",
	  privacy        => "OPEN",
	  active         => 1,
	  location_id    => $loc->location_id,
	  created_at     => $now,
	});
    return $event;
}


