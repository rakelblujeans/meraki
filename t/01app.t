#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'DanceParty';

ok( request('/map')->is_success, 'Request should succeed' );

done_testing();
