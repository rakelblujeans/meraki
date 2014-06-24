package DanceParty::Form::EventFormHandler;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
use HTML::FormHandler::Types (':all');
use Data::Dumper::Concise;
use DateTime::Format::Strptime;

has 'schema' => ( 
    is => 'ro', 
    required => 1
    );

has_field 'submit' => ( type => 'Submit' );
has_field 'sync_to_fb' => (
    type => 'Checkbox',
    label => 'Sync to Facebook',
    );
has_field 'location_id' => ( 
    type => 'Select', 
    label => 'Venue',
    empty_select => 'Select One...',
    default => 'Select One...',
    required => 1,
    );
has_field 'event_name' => (
    type => 'Text',
    label => 'Name',
    minlength => 5,
    maxlength => 100,
    required => 1,
    );
has_field 'organizer_name' => (
    type => 'Text',
    minlength => 5,
    maxlength => 100,
    required => 1,
    );
has_field 'email' => (
    apply => [ Email ],
    ); 
has_field 'music_genre' => (
    type => 'Text',
    minlength => 5,
    maxlength => 100,
    required => 1,
    );
has_field 'artists' => (
    type => 'Text',
    minlength => 5,
    maxlength => 100,
    required => 1,
    );
has_field 'start_time' => ( 
    default => '10:00 PM',
    label => 'Start Time: (HH:MM AM/PM)',
    type => 'Text',
    minlength => 5,
    maxlength => 25,
    required => 1,
    );
has_field 'more_info' => (
    maxlength => 100,
    label => 'More info',
    );
has_field 'youtube_url' => (
    maxlength => 500,
    label => 'Youtube Embed Code',
    );
has_field 'tickets_url' => (
    maxlength => 100,
    label => 'Tickets url',
    );
has_field 'ticket_price' => (
    maxlength => 100,
    type => 'Text',
    label => 'Ticket Cost',
    );
has_field 'additional_description' => (
    maxlength => 100,
    type => 'Text',
    label => 'Additional Description',
    );
has_field 'privacy' => (
    maxlength => 100,
    type => 'Select', 
    label => 'Privacy',
    empty_select => 'Select One...',
    default => 'Select One...',
    required => 1,
    );

has_field 'start_day'=> ( 
    default => DateTime->today->ymd, 
    type => 'Date',
    format => '%F',
    minlength => 5,
    maxlength => 25,
    required => 1,
);

sub options_privacy {
    my $self = shift;
    return [ { value =>'OPEN', label => 'Open' }, 
	     { value => 'SECRET', label => 'Secret' },
	     { value => 'FRIENDS', label => 'Friends' } ];
}

sub options_location_id {
    my $self = shift;
    my @locs = $self->schema->resultset('Location')->search({});
    my @options = map{ { value => $_->location_id, 
			 label => $_->name} } @locs;
    unshift @options, { value => '', label => 'Select One...' }; #set default option
    return @options;
}

sub validate_location_id {
    my ($self, $field) = @_;
    my $loc = $self->schema->resultset('Location')->search({ location_id => $field->value });
    unless ($loc) {
	$field->add_error('Invalid location');
    }
}

sub validate_name {
    my ($self, $field) = @_;
    my $event = $self->schema->resultset('Event')->search({ name => $field->value });
    if ($event->count) {
	warn "GOT COUNT: " . $event->count . "\n";
	$field->add_error('This event has already been added');
    }
}

sub validate_start_day {
    my ($self, $field) = @_; # self is the form
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%F',
        locale    => 'en_US',
        time_zone => 'America/New_York',
	);
    my $dt = $strp->parse_datetime($field->value);
    unless ($dt) {
	$field->add_error('Invalid date. Must be YY-MM-DD');
    }
    if ($dt < DateTime->today) {
	$field->add_error('Date must be in the future');
    }
}

sub validate_start_time {
    my ($self, $field) = @_; # self is the form
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%I:%M %p',
        locale    => 'en_US',
        time_zone => 'America/New_York',
	);
    my $dt = $strp->parse_datetime($field->value);
    unless ($dt) {
	$field->add_error('Invalid time. Must be hh::mm AM/PMD');
    }
}

1;
