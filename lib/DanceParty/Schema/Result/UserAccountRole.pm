use utf8;
package DanceParty::Schema::Result::UserAccountRole;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("user_account_role");
__PACKAGE__->add_columns(
    "user_account_id", { data_type => 'integer', },
    "role_id", { data_type => 'integer', }, 
    "created_at", { data_type => 'timestamp', 
		    set_on_create => 1, },
    "updated_at", { data_type => 'timestamp', 
		    set_on_update => 1, is_nullable => 1, },
    );

__PACKAGE__->set_primary_key(qw[user_account_id role_id]);
__PACKAGE__->add_unique_constraint([qw/user_account_id role_id/]);

__PACKAGE__->belongs_to(
    'user_account' => 'DanceParty::Schema::Result::UserAccount',
    'user_account_id'
    );
__PACKAGE__->belongs_to(
    'role' => 'DanceParty::Schema::Result::Role',
    'role_id'
    );

__PACKAGE__->meta->make_immutable;
1;
