use utf8;
package DanceParty::Schema::Result::FBEvent;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

# Extends info in Event.pm

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");
__PACKAGE__->table("fbevent");
__PACKAGE__->add_columns(
    "fbevent_id",
    {
	data_type         => "integer",
	is_auto_increment => 1,
	is_nullable       => 0,
    },
    "event_id",
    { data_type => "int", is_nullable => 0 },
    "fb_id",
    { data_type => "text", is_nullable => 0 },
    'active',
    { data_type => 'bool', is_nullable => 0, default_value => 'false' },
    'created_at',
    { data_type => 'timestamp',
      set_on_create => 1, },
    'updated_at',
    { data_type => 'timestamp',
      set_on_update => 1, is_nullable => 1, },
    );

__PACKAGE__->set_primary_key("fbevent_id");
__PACKAGE__->add_unique_constraint(["fb_id"]);

__PACKAGE__->belongs_to(
    event => 'DanceParty::Schema::Result::Event',
    'event_id');

__PACKAGE__->meta->make_immutable;
1;
