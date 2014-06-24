package DanceParty::ControllerRole::Utils;
use MooseX::MethodAttributes::Role;
use Data::Dumper::Concise;

=head1 NAME

DanceParty::ControllerRole::Utils

=head1 DESCRIPTION

ControllerRole encapsulating private utility Catalyst functions.

=head1 METHODS

=cut

=head2 _process_status_msgs

    Loads status/error messages.

=cut
sub _process_status_msgs :Private {
    my ($self, $c) = @_;

    $c->load_status_msgs;
    if (ref $c->stash->{'error_msg'} eq 'HASH') {
	my $msg = delete $c->stash->{'error_msg'};
	my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
	$msg = $coder->encode( $msg );
	$c->stash->{'login_form_error_msg'} = $msg;
    }

    # TODO: get rid of this
    # is this user authorized to view event/venue links?
    #$c->stash(is_admin => $c->session->{is_admin});
}

=head2 redirect_error

    Redirects the user to a new page and loads a message into the 
    error msg stash.
    Args:
    - [optional]: pagenum
    - error message
    - url to redirect to

=cut
sub redirect_error :Private {
    my ($self, $c, $pagenum, $msg, $url) = @_;
    return $c->res->redirect( 
	$c->uri_for($url, 
		    {  page => $pagenum,
		       mid  => $c->set_error_msg($msg) }
	))
	&& $c->detach;
}

=head2 redirect_success

    Redirects the user to a new page and loads a message into the 
    status msg stash.    
    Args:
    - [optional]: pagenum
    - error message
    - url to redirect to

=cut
sub redirect_success :Private {
    my ($self, $c, $pagenum, $msg, $url) = @_;
    return $c->res->redirect(
	$c->uri_for($url,
		    {  page => $pagenum,
		       mid => $c->set_status_msg($msg) }
	))
	&& $c->detach;
}

=head1 AUTHOR

    Raquel Bujans

=head1 COPYRIGHT

    Raquel Bujans

=cut

1;
