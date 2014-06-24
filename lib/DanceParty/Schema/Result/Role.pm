use utf8;
package DanceParty::Schema::Result::Role;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
    "role_id", { data_type => 'serial', is_auto_increment => 1 },
    "role_name", { data_type => 'text', },
    );

__PACKAGE__->set_primary_key('role_id');
__PACKAGE__->add_unique_constraint(['role_name']);


__PACKAGE__->has_many(
    'user_account_roles' => 'DanceParty::Schema::Result::UserAccountRole',
    'role_id');

__PACKAGE__->meta->make_immutable;
1;
