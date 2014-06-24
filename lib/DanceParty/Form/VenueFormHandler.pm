package DanceParty::Form::VenueFormHandler;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
use HTML::FormHandler::Types (':all');
use Geo::Coder::Google;

has 'schema' => ( 
    is => 'ro', 
    required => 1
    );

has_field 'submit' => ( type => 'Submit' );

has_field 'phone' => (
    type => 'Text',
    minlength => 9,
    maxlength => 20,
);

has_field 'url' => (
    type => 'Text',
    minlength => 5,
    maxlength => 100,
);

has_field 'location_name' => (
    type => 'Text',
    label => 'Venue name',
    minlength => 5,
    maxlength => 100,
    required => 1,
);

has_field 'location_type_id' => (
    type => 'Select',
    empty_select => 'Select One...',
    default => 'Select One...',
    label => 'Description',
    required => 1,
);

has_field 'address' => (
    type => 'Text',
    minlength => 5,
    maxlength => 100,
    required => 1,
);

sub options_location_type_id {
    my $self = shift;
    my @categories = $self->schema->resultset('LocationType')->search({});
    my @options = map { { value => $_->location_type_id,
			  label => $_->location_type } } @categories;
    unshift @options, { value => '', label => 'Select One...' };
    return @options;
}

sub validate_location_type_id {
    my ($self, $field) = @_;
    my $cat = $self->schema->resultset('LocationType')->search(
	{ location_type_id => $field->value });
    unless ($cat) {
	$field->add_error('Invalid location description');
    }
}




1;
