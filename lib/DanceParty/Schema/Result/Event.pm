use utf8;
package DanceParty::Schema::Result::Event;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("event");
__PACKAGE__->add_columns(
    "event_id",
    {
	data_type         => "integer",
	is_auto_increment => 1,
	is_nullable       => 0,
	sequence          => "event_event_id_seq",
    },
    "name",
    { data_type => "text", is_nullable => 0 },
    "organizer_name",
    { data_type => "text", is_nullable => 0 },
    "email",
    { data_type => "text", is_nullable => 1 },
    "music_genre",
    { data_type => "text", is_nullable => 0 },
    "artists",
    { data_type => "text", is_nullable => 0 },
    "start_time",
    { data_type => "timestamp with time zone", is_nullable => 0 },
    "more_info",
    { data_type => "text", is_nullable => 1 },
    "youtube_url",
    { data_type => "text", is_nullable => 1 }, 
    "tickets_url",
    { data_type => "text", is_nullable => 1 },
    "ticket_price",
    { data_type => "text" },
    "additional_description",
    { data_type => "text", is_nullable => 1 },
    "privacy",
    { data_type => "text", is_nullable=> 0, default_value => 'OPEN' }, #options are OPEN, SECRET FRIENDS #TODO
    "location_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "active",
    { data_type => 'bool', is_nullable => 0, default_value => 'true' },
    'created_at',
    { data_type => 'timestamp',
      set_on_create => 1, },
    'updated_at',
    { data_type => 'timestamp',
      set_on_update => 1, is_nullable => 1, },
    );

__PACKAGE__->set_primary_key("event_id");

__PACKAGE__->belongs_to(
  "location",
  "DanceParty::Schema::Result::Location",
    'location_id',
);

__PACKAGE__->might_have(
    fbevent => 'DanceParty::Schema::Result::FBEvent',
    'event_id');

__PACKAGE__->has_many(
    event_users => 'DanceParty::Schema::Result::EventUser',
    'event_id');

__PACKAGE__->many_to_many(
    'users' => 'event_users',
    'user_account');

sub is_creator {
    my ($self, $user) = @_;
    my $found_user = $self->users->find({ user_account_id => $user->user_account_id });
    return ($found_user) ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;
1;
