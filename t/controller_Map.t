use strict;
use warnings;
use Test::More;


use Catalyst::Test 'DanceParty';
use DanceParty::Controller::Map;

ok( request('/map')->is_success, 'Request /map should succeed' );
ok( request('/map/add_venue')->is_redirect, 'Request /map/add_venue should succeed' );
#ok( request('/map/add_event')->is_redirect, 'Request /map/add_event should succeed' );


done_testing();
