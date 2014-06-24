package DanceParty::Controller::Events;
use Moose;
use namespace::autoclean;
use Data::Dumper::Concise;
use DanceParty::Form::EventFormHandler;
use DateTime::Format::Strptime;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller'; }
with 'DanceParty::ControllerRole::FormVerification';
with 'DanceParty::ControllerRole::Auth';
with 'DanceParty::ControllerRole::Utils';
with 'DanceParty::ControllerRole::FacebookPermissions';

=head1 NAME

DanceParty::Controller::Events - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller to handle event display and management.

=head1 METHODS

=cut


=head2 base
    
    Base function for the controller. All other functions chain off this.
    Checks if user is authorized to access these pages.
    Displays any error/success messages.
=cut
sub base :Chained('/') :PathPart('events') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $self->_check_authorization($c); #checks user role permissions
    $self->_process_status_msgs($c);

    if ($c->req->params->{'code'} &&
	$c->req->params->{'state'} ) {
	#$c->log->warn("EXCHANGING CODE\n");
	$self->exchange_code_for_token($c, $c->uri_for("/events"));
    }
}

=head2 _get_events

    Private helper method that pulls info for all events 
    for the given time period (past or future)
    using a paging mechanism. Stash info as a hash.

=cut
sub _get_events :Private { #:Chained('base') {
    my ( $self, $c, $time ) = @_;
    $c->stash(template => 'events/index.tt2');
    my @events_arr = ();
    my $pagenum = $c->req->params->{page} || 1;

    # update code, if provided
    my $code = $c->req->params->{'code'};
    
    # lookup user's timezone, use that to calculate what "now" is
    my $tz = $c->user->time_zone();
    my $now = DateTime->now->clone();
    $now->set_time_zone($tz);

    my %args = ();

    # get events for either past or future
    if ($time == 1) {
	$args{'start_time'} = { '>=' => $now };
    } elsif ($time == -1) {
	$args{'start_time'} = { '<' => $now };
    }

    # break the returned events up into pages for faster loading
    my $events = $c->model('DB::Event')->search(
	{ active => 1,
	  %args },
	{ page => $pagenum, rows => 100 });
    my $pager = $events->pager();
    #$c->log->warn("GOT EVENTS:[" . $events->count . "] $time\n");
    foreach my $event_rs ($events->all) {
	my %event = $event_rs->get_inflated_columns;
	my $loc_name = $c->model('DB::Location')->find(
	    { location_id => $event{'location_id'} })->name;
	# TODO: clean up later?
	my $on_fb = $event_rs->fbevent && $event_rs->fbevent->active == 1;
	
	push @events_arr, {
	    %event,
	    ($on_fb ? (fb_id => $event_rs->fbevent->fb_id) : ()),
	    location    => $loc_name,
	    on_facebook => ( $on_fb ? 'Yes' : 'No' ),
	    user_can_edit => $event_rs->is_creator($c->user),
	};
    }

    $c->stash(events       => \@events_arr,
	      current_page => $pager->current_page,
	      prev_page    => $pager->previous_page,
	      next_page    => $pager->next_page,
	      showing_upcoming => $time,
	);
}

=head2 index

    Pulls info for all upcoming events.

=cut
sub index :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    return $self->_get_events($c, 1);
}

=head2 past
    
    Pulls info for all past events.

=cut
sub past :Chained('base') :Args(0) {
    my ( $self, $c ) = @_;
    return $self->_get_events($c, -1);
}

=head2 delete
    
    Delete an event with the specified id.
    $id matches Event::event_id.
=cut
sub delete :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    my $pagenum = $c->req->params->{page} || 1;
    my $event = $c->model('DB::Event')->find({ event_id => $id });
    my $name = $event->name;
    unless ($event->is_creator($c, $c->user)) {
	$c->log->warn("Error deleting event: you are not the event creator\n");
	$self->redirect_error($pagenum, "Error deleting event - $name!", '/events');
    }

    if ($event) {
	$event->update({ active => 0 });
	$self->redirect_success($c, $pagenum, "Event $name deleted!", '/events');
    } else {
	$c->log->warn("Error deleting event: event not found\n");
	$self->redirect_error($pagenum, "Error deleting event - $name!", '/events');
    }
}

=head2 _validate_event

    Private method used to handle event form validation. 
    Called when creating/editing events.

=cut
sub _validate_event :Private {
    my ($self, $c, $error_action) = @_;
    my $form = DanceParty::Form::EventFormHandler->new( schema => $c->model('DB') );
    unless ($self->process_form($c, 'event_form', $form, $error_action)) {
	return;
    }

    my $fif = $form->fif;
    $form->clear;
    $fif->{name} = delete $fif->{event_name};
    return $fif;
}

=head2 _validate_create_event
    
    Private method used to isolate event creation logic.
    After form validation passes, event info is stored in the db.
    It is also optionally sent to fb.

=cut
sub _validate_create_event :Private {
    my ($self, $c) = @_;
    my $fif = $self->_validate_event($c, '/events/add');
    return unless $fif;

    $fif->{active} = 'true';
    my $new_event = $c->model('DB::Event')->create_event($fif, $c->user->obj);

    if ($fif->{'sync_to_fb'}) {
	# cross-post event to Facebook, ResidentAdvisor, Twitter, etc
	$c->model('Facebook')->post_event($c->user, $new_event);
    }
    return $new_event;
}

=head2 _validate_edit_event
    
    Private method used to isolate event editing logic.
    After form validation passes, event info is updated in the db.
    It is also optionally sent to fb.

=cut
sub _validate_edit_event :Private {
    my ($self, $c, $id) = @_;
    my $fif = $self->_validate_event($c, "/events/edit/$id");
    my $sync_to_fb = delete $fif->{'sync_to_fb'};
    my $event = $c->model('DB::Event')->update_event($fif, $id);

    if ($sync_to_fb) {
	# cross-post event to Facebook, ResidentAdvisor, Twitter, etc
	my $fb_event = $c->model('Facebook')->post_event_fb(
	    $c->user->fbuser, $event,
	    $event->location->fblocation);
    }

    return $event;
}

=head2 add

    Stashes form data and sets the url the form should
    submit to.

=cut
sub add :Chained('base') {
    my ($self, $c) = @_;
    $c->stash(template => 'events/event_form.tt2');
    my $pagenum = $c->req->params->{page} || 1;
    my $event_form = DanceParty::Form::EventFormHandler->new( schema => $c->model('DB') );
    
    $c->stash(%{$c->req->params},
	      event_form    => $event_form,
	      submit_action => $c->uri_for('/events/submit_add', 
					   { page => $pagenum } ));
}

=head2 submit_add

    Validates user-submitted form data and then redirects
    to the general event listing if successful. Otherwise 
    the user if forced to re-enter form data.
    
=cut
sub submit_add :Chained('base') :PathPart {
    my ($self, $c) = @_;
    my $pagenum = $c->req->params->{page} || 1;

    my $new_event = $self->_validate_create_event($c);

    if ($new_event) {
	$self->redirect_success($c, $pagenum, 'Event added successfully!', '/events');
    } else {
	$c->log->warn("Error submitting new event\n");
	$self->redirect_error($pagenum, $c->set_error_msg('Adding the event failed. Try again.!'), '/events/add');
    }
}

=head2 detail

    View an event's detailed info. Event ID must be supplied.

=cut
sub detail :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash(template => 'events/detail.tt2');
    my $event = $c->model('DB::Event')->find({ event_id => $id });
    my %data = $event->get_inflated_columns;
    my $loc = $c->model('DB::Location')->find(
	{ location_id => $event->location_id });
    
    $c->stash(event         => \%data,
	      is_creator    => $event->is_creator($c->user),
	      location_id   => $loc->location_id,
	      location_name => $loc->name);
}

=head2 edit

    Edit an event's details. Event info is displayed in a form.
    Must supply an event ID.

=cut
sub edit :Chained('base') :PathPart('edit') :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash(template => 'events/event_form.tt2');
    my $pagenum = $c->req->params->{page} || 1;
    my $event = $c->model('DB::Event')->find({ event_id => $id });
    unless ($event->is_creator($c->user)) {
	$c->log->warn("Error editing event: you are not the event creator\n");
	$self->redirect_error($pagenum, $c->set_error_msg('Editing the event failed. Try again.!'), '/events/edit');
    }

    my %data = $event->get_inflated_columns;
    my $event_form = DanceParty::Form::EventFormHandler->new( schema => $c->model('DB') );
    $c->stash(event         => \%data,
	      event_form    => $event_form,
	      submit_action => $c->uri_for('/events/submit_edit/' . $id, ,
					   { page => $pagenum } ));
}

=head2 submit_edit

    Submit changes to an event's details. If successful,
    redirect back to the main events list.

=cut
sub submit_edit :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash(template => 'events/event_form.tt2');
    my $pagenum = $c->req->params->{'page'};
    my $edited_event = $self->_validate_edit_event($c, $id);
    unless ($edited_event->is_creator($c->user)) {
	$c->log->warn("Error submitting edited event: you are not the event creator\n");
	$self->redirect_error($pagenum, $c->set_error_msg('Editing the event failed. Try again.!'), '/events/edit');
    }

    if ($edited_event) {
	$self->redirect_success($c, $pagenum, 'Event updated', '/events');
    }
}

=head2 delete_multiple

    Shortcut method for deleting several events at once.
    Event checkboxes are checked and submitted by the form.
    Event IDs are supplied by the 'selected' request param.

=cut
sub delete_multiple :Chained('base') :Args(0) {
    my ($self, $c) = @_;
    my $pagenum = $c->req->params->{'page'} || 1;
    my $selected_ids = $c->req->params->{'selected'};
    if ($selected_ids) {
	my @events = $c->model('DB::Event')->search(
	    { event_id => { -in => $selected_ids } });
	foreach my $e (@events) {
	    if ($e->is_creator($c->user)) {
		$e->update({ active => 0 });
	    }
	}
    }
    $self->redirect_success($c, $pagenum, ($selected_ids) ? 'Events deleted' : '', '/events');
}

=head2 fbpost

    Push event info to Facebook using the Graph API. 

=cut
sub fbpost :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    my $pagenum = $c->req->params->{'page'} || 1;

    unless ($c->user->active_token) {
	$c->log->warn("Error occured while posting even to FB");
	$self->redirect_error(
	    $pagenum, 
	    $c->set_error_msg("Error occured while posting even to FB"), '/events');
    }
    
    my $event = $c->model('DB::Event')->find(
	{ event_id => $id });
    unless ($event->is_creator($c->user)) {
	$c->log->warn("Error occured while posting even to FB");
	$self->redirect_error(
	    $pagenum, 
	    $c->set_error_msg("Error occured while posting even to FB"), '/events');
    }

    # TODO: handle when users have multiple accounts & tokens
    #$c->log->warn("QUERY PERMS\n");
    unless ($c->model('Facebook')->query_permissions($c->user->active_token)) {
	#$c->log->warn("NO PERMISSIONS FOUND!\n");
	return $self->request_permissions(
	    $c, 
	    $c->uri_for("/events")) && $c->detach;
    }

    my $success = $c->model('Facebook')->post_event(
	$c->user->active_token, $event,
	$event->location->fblocation);
    
    my $mid_msg = ($success) ? 'Event posted on Facebook' : 'Event failed to post to Facebook';
    $self->redirect_success($c, $pagenum, $mid_msg, '/events');
}

=head2 fbremove

    Remove an event's info from Facebook

=cut
sub fbremove :Chained('base') :Args(1) {
    my ($self, $c, $id) = @_;
    my $pagenum = $c->req->params->{'page'} || 1;

    #$c->log->warn("INSIDE FBREMOVE\n");
    my $event = $c->model('DB::Event')->find(
	{ event_id => $id });
    unless ($event->is_creator($c->user)) {
	$c->log->warn("Error occured while remving event from FB");
	$self->redirect_error(
	    $pagenum, 
	    $c->set_error_msg("Error occured while remving event from FB"), '/events');
    }

    my $mid_msg = "Removing the event from Facebook failed";
    if ($event->fbevent) {
	my $success = $c->model('Facebook')->delete_event(	
	    $event->fbevent->fb_id,
	    $c->user->active_token);
	$mid_msg = "Event removed from Facebook";
    }	
    
    $self->redirect_success($c, $pagenum, $mid_msg, '/events');
}

=head2 fbremove_multiple

    Shortcut methods for removing multiple events from Facebook
    at the same time.

=cut
sub fbremove_multiple :Chained('base') :Args(0) {
    my ($self, $c, $id) = @_;
    my $pagenum = $c->req->params->{'page'} || 1;
    my $selected_ids = $c->req->params->{'selected'};
    my $count = 0;
    my $mid_msg = "Removing the event from Facebook failed";
    if ($selected_ids) {
	my @events = $c->model('DB::Event')->search(
	    { event_id => { -in => $selected_ids } });
	foreach my $event (@events) {
	    next unless $event->is_creator($c->user);
	    if ($event->fbevent) {
		my $success = $c->model('Facebook')->delete_event(	
		    $event->fbevent->fb_id,
		    $c->user->active_token);
		$count++;
	    }
	}
	$mid_msg = "$count Event(s) removed from Facebook";
    }
    $self->redirect_success($c, $pagenum, $mid_msg, '/events');
}

=head2 fbpost_multiple

    Shortcut methods for posting multiple events from Facebook
    at the same time.

=cut
sub fbpost_multiple :Chained('base') :Args(0) {
    my ($self, $c) = @_;
    my $pagenum = $c->req->params->{'page'} || 1;
    my $selected_ids = $c->req->params->{'selected'};
    my $count = 0;
    if ($selected_ids) {
	my @events = $c->model('DB::Event')->search(
	    { event_id => { -in => $selected_ids } });
	foreach my $e (@events) {
	    next unless $e->is_creator($c->user);
	    my $already_on_fb = $e->fbevent && ($e->fbevent->active == 1);
	    #$c->log->warn("ALREADY ON FB? $already_on_fb \n");
	    if (!$e->fbevent || !$already_on_fb) {
		$c->model('Facebook')->post_event(
		    $c->user->active_token, $e,
		    $e->location->fblocation);
		$count++;
	    }
	}
    }
    $self->redirect_success($c, $pagenum, ($selected_ids) ? "Posted $count event(s) to Facebook" : '', '/events');
}

=head1 AUTHOR

    Raquel Bujans

=head1 COPYRIGHT

    Raquel Bujans

=cut

__PACKAGE__->meta->make_immutable;

1;
