package DanceParty::Schema::ResultSet::Location;
use strict;
use warnings;
use DateTime::Format::Strptime;
use base 'DBIx::Class::ResultSet';
use Data::Dumper::Concise;
use Geo::Coder::Google;

sub create_allowed_by {
    my ($self, $user) = @_;
    return $user->has_role('admin') ||
	$user->has_role('super_admin');
}

sub create_loc {
    my ($self, $results, $user) = @_;
    my $new_loc = $self->result_source->schema->resultset('Location')->create(
	$self->_build_loc($results));
    $new_loc->add_to_users($user);
    return $new_loc;
}

sub update_loc {
    my ($self, $results, $id) = @_;
    my $loc = $self->result_source->schema->resultset('Location')->find({location_id => $id});
    $loc->update($self->_build_loc($results));
    return $loc;
}

sub _build_loc {
    my ($self, $results) = @_;
    my $loc_type = $self->result_source->schema->resultset('LocationType')->find(
        { location_type_id => $results->{'location_type_id'} });
    my $geocoder = Geo::Coder::Google->new(apiver => 3);
    my $geocoded_loc = $geocoder->geocode(
        location => $results->{'address'} );
    die "Invalid address" unless $geocoded_loc;
    my $coords = $geocoded_loc->{'geometry'}{'location'};
    die "Invalid coordinates" unless $coords;
    return { name             => $results->{'name'},
	     location_type_id => $loc_type->location_type_id,
	     phone            => $results->{'phone'},
	     address          => $results->{'address'},
	     url              => $results->{'url'},
	     lat              => $coords->{'lat'},
	     long             => $coords->{'lng'},
	     active           => 1,
    };
}

1;
