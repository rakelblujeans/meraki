package DanceParty::Controller::Venues;
use Moose;
use namespace::autoclean;
use Data::Dumper::Concise;
use DanceParty::Form::VenueCreateFormHandler;
use DanceParty::Form::VenueEditFormHandler;

BEGIN { extends 'Catalyst::Controller'; }
with 'DanceParty::ControllerRole::FormVerification';
with 'DanceParty::ControllerRole::Utils';
with 'DanceParty::ControllerRole::Auth';

=head1 NAME

DanceParty::Controller::Venues - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 base

    Base function for the controller. All other functions chain off this.
    Displays any error/success messages.

=cut

sub base :Chained('/') :PathPart('venues') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $self->_check_authorization($c);
    $self->_process_status_msgs($c);
}

=head2 index

    Stashes paged info about all venue locations.

=cut
sub index :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(template => 'venues/index.tt2');
    my @venues_arr = ();
    my $pagenum = $c->req->params->{page} || 1;
    my @categories_rs = $c->model('DB::LocationType')->all;
    my %categories = map { $_->location_type_id => $_->location_type } @categories_rs;
    # TODO: localize time
    my $dtf = $c->model('DB')->storage->datetime_parser;
    my $venues = $c->model('DB::Location')->search(
	undef, 
	{ page => $pagenum, 
	  rows => 100, 
	  order_by => 'name' });
    my $pager = $venues->pager();

    foreach my $venue_rs ($venues->all) {
	my %venue = $venue_rs->get_inflated_columns;
	next unless $venue{'active'};

	my $events_count = $c->model('DB::Event')->count(
	    { start_time => { '>' => $dtf->format_datetime(DateTime->now()) },
	      location_id => $venue{'location_id'} 
	    });
	push @venues_arr, { %venue, 
			    category   => $categories{$venue{'location_type_id'}},
			    num_events => $events_count,
	};
    }

     $c->stash(venues       => \@venues_arr,
	       current_page => $pager->current_page,
	       prev_page    => $pager->previous_page,
	       next_page    => $pager->next_page, );
}

=head2 detail

    Displays extended info about a location.

=cut
sub detail :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash(template => 'venues/detail.tt2');
    my $venue = $c->model('DB::Location')->find({ location_id => $id });
    my %data = $venue->get_inflated_columns;
    my $dtf = $c->model('DB')->storage->datetime_parser;
    # TODO: localize time
    my $events = $c->model('DB::Event')->search(
	{ start_time  => { '>' => $dtf->format_datetime(DateTime->now()) },
	  location_id => $venue->location_id,
	});
    
    # TODO: pass in events hash with only relevant fields
    # don't pass db object to the view
    $c->stash(venue         => \%data,
	      events        => $events,
	      location_type => $venue->location_type->location_type,
	      is_creator    => $venue->is_creator($c->user));
}

=head2 delete
    
    De-activate a location in our database so that it is no
    longer displayed on the website. (We never truly delete)

=cut
sub delete :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    my $pagenum = $c->req->params->{page} || 1;
    my $venue = $c->model('DB::Location')->find({ location_id => $id });
    my $name = $venue->name;
    if ($venue) {
	$venue->update({ active => 0 });
	$self->redirect_success($c, $pagenum, "Event $name deleted!", '/venues');
    } else {
	$c->log->warn("Error deleting event - $name not found!\n");
	$self->redirect_error(
	    $pagenum, 
	    $self->redirect_error($pagenum, "Error deleting event - $name!", '/venues'));
    }
}

=head2 _validate_venue

    Private method that handles form validation when
    creating/editing venues.
    
=cut
sub _validate_venue :Private {
    my ($self, $c, $form, $error_action) = @_;
    unless ($self->process_form($c, 'venue_form', $form, $error_action)) {
	return;
    }

    my $fif = $form->fif;
    $fif->{'name'} = delete $fif->{'location_name'};
    $form->clear;
    return $fif;
}

=head2 _validate_create_venue

    Private method that adds a new venue to our db
    after the form validation passes.

=cut
sub _validate_create_venue :Private {
    my ($self, $c) = @_;
    my $form = DanceParty::Form::VenueCreateFormHandler->new( schema => $c->model('DB') );
    my $fif = $self->_validate_venue($c, $form);
    $fif->{active} = 'true';

    my $new_loc = $c->model('DB::Location')->create_loc($fif, $c->user);
    return $new_loc;
}

=head2 _validate_edited_venue

    Private method that updates a venue in our db
    after the form validation passes.

=cut
sub _validate_edited_venue :Private {
    my ($self, $c, $id) = @_;
    my $form = DanceParty::Form::VenueEditFormHandler->new( schema => $c->model('DB') );
    my $fif = $self->_validate_venue($c, $form, "/venues/edit/$id");

    my $venue = $c->model('DB::Location')->update_loc($fif, $id);
    return $venue;
}

=head2 add

    Stashes form data so that user can create a new event.

=cut
sub add :Chained('base') {
    my ($self, $c) = @_;
    $c->stash(template => 'venues/venue_form.tt2');
    my $pagenum = $c->req->params->{page} || 1;
    my $venue_form = DanceParty::Form::VenueCreateFormHandler->new( schema => $c->model('DB') );
    $c->stash(venue_form    => $venue_form,
	      submit_action => $c->uri_for('/venues/submit_add', ,
					   { page => $pagenum} ));
}

=head2 submit_add

    Validates and submitted user-provided input.
    Redirects to the venues listing if successfully added info.

=cut
sub submit_add :Chained('base') :PathPart :Args(0) {
    my ($self, $c) = @_;
    my $pagenum = $c->req->params->{page} || 1;
    my $new_venue = $self->_validate_create_venue($c);

    if ($new_venue) {
	$self->redirect_success($c, $pagenum, 'Venue added successfully!', '/venues');
    } else {
	$c->log->warn("Error adding venue $new_venue\n");
	$self->redirect_error($pagenum, 'Error adding venue. Please try again.', '/venues');
    }
}

=head2 edit

    Presents a location's details in a form.
    Requires a location_id.

=cut
sub edit :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash(template => 'venues/venue_form.tt2');
    my $pagenum = $c->req->params->{page} || 1;
    my $venue = $c->model('DB::Location')->find({ location_id => $id });
    my %data = $venue->get_inflated_columns;
    my $venue_form = DanceParty::Form::VenueEditFormHandler->new( schema => $c->model('DB') );
    $c->stash(venue         => \%data,
	      venue_form    => $venue_form,
	      submit_action => $c->uri_for('/venues/submit_edit/' . $id, , 
					   { page => $pagenum} ));
}

=head2 submit_edit

    Validates a user's changes and updates the db.
    Requires a location_id.    

=cut
sub submit_edit :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    my $pagenum = $c->req->params->{'page'} || 1; 
    #$c->log->warn("CALLING SUBMIT EDIT\n");
    $c->stash(template => 'venues/venue_form.tt2');
    my $edited_venue = $self->_validate_edited_venue($c, $id);

    if ($edited_venue) {
	$self->redirect_success($c, $pagenum, 'Venue updated.', '/venues');
    }
}

=head2 events

    Lists all the upcoming events at a given venue.

=cut
sub events :Chained('base') :Args(2) {
    my ($self, $c, $id, $time) = @_;
    $c->stash(template => 'events/index.tt2');
    my $dtf = $c->model('DB')->storage->datetime_parser;
    my $comparer = ($time eq 'future') ? '>=' : '<';
    my @events_rs = $c->model('DB::Event')->search(
	{ location_id => $id,
	  start_time => { $comparer => $dtf->format_datetime(DateTime->now()) },
	});
    my @events = ();
    foreach my $e (@events_rs) {
	my %data = $e->get_inflated_columns;
	push @events, { %data,
		        on_facebook => ( $data{'fbevent'} ? 'Yes' : 'No' ), };
    }
    $c->stash(events => \@events);
}

=head2 delete_multiple

    Shortcut method for de-activating multiple venues at once.
    Venues are never truly deleted, just hidden from view.

=cut
sub delete_multiple :Chained('base') :Args(0) {
    my ($self, $c) = @_;
    my $pagenum = $c->req->params->{'page'} || 1;
    my $selected_ids = $c->req->params->{'selected'};
    my @venues = $c->model('DB::Location')->search(
	{ location_id => { -in => $selected_ids } });
    foreach my $v (@venues) {
	$v->update({ active => 0 });
    }
    $self->redirect_success($c, $pagenum, 'Venues deleted.', '/venues');
}

=head1 AUTHOR

Raquel Bujans

=head1 LICENSE

Raquel Bujans

=cut

__PACKAGE__->meta->make_immutable;

1;
