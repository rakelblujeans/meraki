package DanceParty::Form::VenueEditFormHandler;
use HTML::FormHandler::Moose;
extends 'DanceParty::Form::VenueFormHandler';
use HTML::FormHandler::Types (':all');
use Geo::Coder::Google;


sub validate_location_name {
    my ($self, $field) = @_;
    my $loc = $self->schema->resultset('Location')->search({ name => $field->value });
    if ($loc->count > 1) {
	$field->add_error('Invalid location name');
    }
}

sub validate_address {
    my ($self, $field) = @_;
    my $addr = $self->schema->resultset('Location')->search({ address => $field->value });
#    if ($addr->count > 1) {
#	$field->add_error('Invalid address specified');
#    }

    my $geocoder = Geo::Coder::Google->new(apiver => 3);
    my $geocoded_loc = $geocoder->geocode(
	location => $self->field('address')->value);
    unless ($geocoded_loc) {
	$self->field('address')->add_error('Invalid address');
    }
    my $coords = $geocoded_loc->{'geometry'}{'location'};
    unless ($coords) {
	$self->field('address')->add_error('Invalid address');
    }

#    $self->field('lat')->value = $coords->{'lat'};
#    warn $self->field('lat')->value;
#    $self->field('long')->value = $coords->{'long'};    
}


1;
