use strict;
use warnings;

use DanceParty;

my $app = DanceParty->apply_default_middlewares(DanceParty->psgi_app);
$app;

