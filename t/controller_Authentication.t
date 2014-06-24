use strict;
use warnings;
use Test::More;


use Catalyst::Test 'DanceParty';
use DanceParty::Controller::Authentication;

ok( request('/auth/login')->is_redirect, 'Login request should succeed' );
ok( request('/auth/logout')->is_redirect, 'Logout request should succeed' );
ok( request('/auth/facebook_is_authed')->is_redirect, 'facebook_is_authed request should succeed' );
ok( request('/auth/registration')->is_success, 'registration request should succeed' );
done_testing();
