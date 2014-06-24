use utf8;
package DanceParty::Schema::Result::LocationUser;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("location_user");
__PACKAGE__->add_columns(
    "location_id", { data_type => 'integer', }, 
    "user_account_id", { data_type => 'integer', },
    "created_at", { data_type => 'timestamp', 
		    set_on_create => 1, },
    );

__PACKAGE__->set_primary_key(qw[location_id user_account_id]);
__PACKAGE__->add_unique_constraint([qw/location_id user_account_id/]);

__PACKAGE__->belongs_to(
    'location' => 'DanceParty::Schema::Result::Location',
    'location_id'
    );

__PACKAGE__->belongs_to(
    'user_account' => 'DanceParty::Schema::Result::UserAccount',
    'user_account_id'
    );

__PACKAGE__->meta->make_immutable;
1;
