use strict;
use warnings;
use Test::More;


use Catalyst::Test 'DanceParty';
use DanceParty::Controller::Venues;

ok( request('/venues')->is_redirect, 'Request should succeed' );
done_testing();
