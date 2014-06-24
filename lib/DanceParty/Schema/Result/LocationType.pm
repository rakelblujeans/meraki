use utf8;
package DanceParty::Schema::Result::LocationType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

DanceParty::Schema::Result::LocationType

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");
__PACKAGE__->table("location_type");
__PACKAGE__->add_columns(
  "location_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "location_type_location_type_id_seq",
  },
  "location_type",
  { data_type => "text", is_nullable => 0 },
    'created_at',
    { data_type => 'timestamp',
      set_on_create => 1, },
);

__PACKAGE__->set_primary_key("location_type_id");

__PACKAGE__->has_many(
  "locations",
  "DanceParty::Schema::Result::Location",
  { "foreign.location_type_id" => "self.location_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 16:32:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nSMIp1oPgZ7oKXobotg0rQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
