use utf8;
package DanceParty::Schema::Result::Location;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

DanceParty::Schema::Result::Location

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");
__PACKAGE__->table("location");
__PACKAGE__->add_columns(
    "location_id",
    {
	data_type         => "integer",
	is_auto_increment => 1,
	is_nullable       => 0,
	sequence          => "location_location_id_seq",
    },
    "location_type_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", size => 100, is_nullable => 0 },
    "phone",
    { data_type => "varchar", size => 100, is_nullable => 1 },
    "address",
    { data_type => "varchar", size => 100, is_nullable => 0 },
    "url",
    { data_type => "varchar", size => 100, is_nullable => 1 },
    "lat",
    { data_type => "double precision", is_nullable => 0 },
    "long",
    { data_type => "double precision", is_nullable => 0 },
    "active",
    { data_type => 'bool', is_nullable => 0, default_value => 1 },
    'created_at',
    { data_type => 'timestamp',
      set_on_create => 1, },
    'updated_at',
    { data_type => 'timestamp',
      set_on_update => 1, is_nullable => 1, },
    );

__PACKAGE__->set_primary_key("location_id");
__PACKAGE__->add_unique_constraint(["name"]);

__PACKAGE__->has_many(
    "events",
    "DanceParty::Schema::Result::Event",
    { "foreign.location_id" => "self.location_id" },
    { cascade_copy => 0, cascade_delete => 0 },
    );

__PACKAGE__->belongs_to(
    "location_type",
    "DanceParty::Schema::Result::LocationType",
    { location_type_id => "location_type_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
    );

__PACKAGE__->might_have(
    'fblocation',
    'DanceParty::Schema::Result::FBLocation',
    'location_id');
__PACKAGE__->has_many(
    'location_users' => 'DanceParty::Schema::Result::LocationUser',
    'location_id'
    );

__PACKAGE__->many_to_many(
    'users' => 'location_users',
    'user_account'
    );

sub is_creator {
    my ($self, $user) = @_;
    my $found_user = $self->users->find({ user_account_id => $user->user_account_id });
    return ($found_user) ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;
1;
