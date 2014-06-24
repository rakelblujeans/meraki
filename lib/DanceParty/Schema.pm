use utf8;
package DanceParty::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE


use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';
our $VERSION = 1;

__PACKAGE__->load_namespaces;
__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory('sql_upgrades/');

# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 16:32:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D8VmJtD+z6n/qu6vVmQy5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
