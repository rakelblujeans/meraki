use utf8;
package DanceParty::Schema::Result::FBLocation;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("fblocation");
__PACKAGE__->add_columns(
    "fblocation_id",
    {
	data_type         => "integer",
	is_auto_increment => 1,
	is_nullable       => 0,
    },
    'location_id',
    { data_type => 'integer', is_nullable => 0 },
    'name',
    { data_type => "text", is_nullable => 0 },
    'is_published',
    { data_type => "text", is_nullable => 0 },
    'website',
    { data_type => "text", is_nullable => 1 },
    'phone',
    { data_type => "text", is_nullable => 1 },
    'street',
    { data_type => "text", is_nullable => 1 },
    'city',
    { data_type => "text", is_nullable => 1 },
    'state',
    { data_type => "text", is_nullable => 1 },
    'country',
    { data_type => "text", is_nullable => 1 },
    'zip',
    { data_type => "text", is_nullable => 1 },
    'latitude',
    { data_type => "text", is_nullable => 0 },
    'longitude',
    { data_type => "text", is_nullable => 0 },
    'category',
    { data_type => "text", is_nullable => 0 },
    'id',
    { data_type => "bigint", is_nullable => 0 },
    'link',
    { data_type => "text", is_nullable => 1 },
    "active",
    { data_type => 'bool', is_nullable => 0, default_value => 'false' },
    'created_at',
    { data_type => 'timestamp',
      set_on_create => 1, },
    'updated_at',
    { data_type => 'timestamp',
      set_on_update => 1, is_nullable => 1, },
    );

__PACKAGE__->set_primary_key("fblocation_id");
__PACKAGE__->add_unique_constraint(["id"]);

__PACKAGE__->belongs_to(
    'location',
    'DanceParty::Schema::Result::Location',
    'location_id');

__PACKAGE__->meta->make_immutable;
1;
