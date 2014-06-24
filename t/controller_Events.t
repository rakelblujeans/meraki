use strict;
use warnings;
use Test::More;

use Catalyst::Test 'DanceParty';
use DanceParty::Controller::Events;

ok( request('/events')->is_redirect, 'Request should succeed' );
done_testing();
