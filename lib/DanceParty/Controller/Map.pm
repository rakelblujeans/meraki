package DanceParty::Controller::Map;
use Moose;
use namespace::autoclean;
use Data::Dumper::Concise;
use DBIx::Class::ResultClass::HashRefInflator;
use Geo::Coder::Google;
use DanceParty::Form::SearchFormHandler;
use DanceParty::Model::Math;
use JSON::XS;
use LWP::UserAgent;

BEGIN { extends 'Catalyst::Controller'; }
with 'DanceParty::ControllerRole::FormVerification';
with 'DanceParty::ControllerRole::Utils';

=head1 NAME

DanceParty::Controller::Map - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller that handles displaying events on a Google Map.

=head1 METHODS

=cut


=head2 base

    Base function for the controller. All other functions chain off this.
    Displays any error/success messages.

=cut

sub base :Chained('/') :PathPart('map') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $self->_process_status_msgs($c);
}


=head2 index

    Determines where the map should be centered.
    
=cut
sub index :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(template => 'map/index.tt2');

    # give user supplied coords/location preference
    my ($lat, $lng);
    my $loc_id =$c->req->params->{'location_id'};
    if ($loc_id) {
	my $loc = $c->model('DB::Location')->find({ location_id => $loc_id });
	$lat = $loc->lat;
	$lng = $loc->long;
    }
    unless ($lat && $lng) {
	if ($c->user && $c->user->lat && $c->user->lng ) {
	    my $user = $c->model('DB::UserAccount')->find(
		{ user_account_id => $c->user->id });
	    $lat = $user->lat;
	    $lng = $user->lng;
	} else {
	    # center on NYC by default
	    $lat = '40.720331';
	    $lng = '-73.952236';
	}
    }

    $self->_stash_json_events($c);
    $c->stash(map_center       => { lat => $lat, lng => $lng },
	      fb_app_id        => $c->config->{'Facebook'}{'app_id'},
	      fb_secret        => $c->config->{'Facebook'}{'secret'},
	      %{$c->req->params},
	);
}

=head2 _validate_search
    
    Validates/sanitizes the search terms.
    
=cut
sub _validate_search :Private {
    my ($self, $c, $error_action) = @_;
    my $form = DanceParty::Form::SearchFormHandler->new( schema => $c->model('DB') );
    unless ($self->process_form($c, 'search_form', $form, $error_action)) {
	return;
    }

    my $fif = $form->fif;
    $form->clear;
    return $fif;
}

=head2 _stash_json_events

    Private method that returns a list of relevant events.
    Filters events by different criteria, in this order:
    - according to search terms
    - according to lat/lng
    - according to user's city    

=cut
# TODO: pull this out into an API class?
sub _stash_json_events :Private {
    my ( $self, $c ) = @_;
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

    # restrict by search terms
    my @terms;
    if ($c->req->params->{'search_terms'}) {
	my $fif = $self->_validate_search($c, '/map');
	return unless $fif;
	
	@terms = split(' ', $fif->{search_terms});
	@terms = map { '%' . $_ . '%' } @terms;
    }
    my $valid_events = $c->model('DB::Event')->find_events(\@terms);
    
    # TODO: find the center of these search results and re-center map
    # $self->_calc_event_loc_center($valid_events);

    # if the user is searching by lat/lng or location_id, give that preference.
    # otherwise use the user_account default.
    # If that's blank for some reason, default to NYC.
    my $lat = $c->req->params->{'lat'};
    my $lng = $c->req->params->{'lng'};
    my $loc_id =$c->req->params->{'location_id'};
    if ($loc_id) {
	my $loc = $c->model('DB::Location')->find({ location_id => $loc_id });
	$lat = $loc->lat;
	$lng = $loc->long;
    }

    #$c->log->warn($lat .' ' . $lng . "\n");
    if ($lat && $lng) {
	$valid_events = $c->model('Math')->restrict_events_by_dist($lat, $lng, $valid_events);
    } elsif ($c->user) {
	my $user = $c->model('DB::UserAccount')->find({ user_account_id => $c->user->id });
	$valid_events = $c->model('Math')->restrict_events_by_user_location($c->user, $valid_events);
    }

    my $json_events = $coder->encode($valid_events);
    #warn Dumper $json_events;
    $c->stash(json_events => $json_events);
}

=head2 json_events

    Called using ajax. Returns a JSONified list of events.

=cut
sub json_events :Chained('base') :Args(0) {
    my ($self, $c) = @_;
    $self->_stash_json_events($c);
    #$c->stash->{current_view} = 'View::JSON';
    return $c->forward('View::JSON');
}

=head1 AUTHOR

Raquel Bujans

=head1 COPYRIGHT

Raquel Bujans

=cut

__PACKAGE__->meta->make_immutable;

1;
