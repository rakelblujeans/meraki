package DanceParty::Form::VenueCreateFormHandler;
use HTML::FormHandler::Moose;
extends 'DanceParty::Form::VenueFormHandler';
use HTML::FormHandler::Types (':all');
use Geo::Coder::Google;

sub validate_location_name {
    my ($self, $field) = @_;
    my $loc = $self->schema->resultset('Location')->search({ name => $field->value });
    if ($loc->count) {
	$field->add_error('This location has already been added');
    }
}

sub validate_address {
    my ($self, $field) = @_;
    my $addr = $self->schema->resultset('Location')->search({ address => $field->value });
#    if ($addr->count) {
#	$field->add_error('This address has already been used');
#    }

    my $geocoder = Geo::Coder::Google->new(apiver => 3);
    my $geocoded_loc = $geocoder->geocode(
	location => $self->field('address')->value);
    unless ($geocoded_loc) {
	$self->field('address')->add_error('Invalid address. Geolocation info not returned from Google');
    }
}



1;
