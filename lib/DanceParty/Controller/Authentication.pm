package DanceParty::Controller::Authentication;
use Moose;
use namespace::autoclean;
use Data::Dumper::Concise;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }
with 'DanceParty::ControllerRole::FormVerification';
with 'DanceParty::ControllerRole::Auth';

=head1 NAME

DanceParty::Controller::Authentication - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller to manage user login and registration.

=head1 METHODS

=cut


=head2 auth

    Base function for the controller. All other functions chain off this.

=cut

sub auth :Chained('/') :PathPart('auth') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->response->content_type = "text/html";
    #$c->response->body('Matched DanceParty::Controller::Authentication in Authentication.');
}

=head2 login

    Verifies user login attempt and passes flow to map controller.

=cut
sub login :Chained('auth') :PathPart :Args(0) {
    my ( $self, $c ) = @_;

    my $result = $self->verify_login($c);
    return $c->res->redirect($c->uri_for('/map') ) && $c->detach;
}

=head2 logout

    Cleans up session/user variables and logs user out.

=cut
sub logout :Chained('auth') :PathPart :Args(0) {
    my ( $self, $c ) = @_;
    # Clear the user's state
    $c->logout;
    
    # Send the user to the starting point
    return $c->res->redirect($c->uri_for('/map')) && $c->detach;
}

=head2 facebook_is_authed

    Verifies credentials using Facebook Graph API

=cut
sub facebook_is_authed :Chained('auth') :PathPart :Args(0) {
    my ($self, $c) = @_;
    my $errorStatus = 'Login failed! Please try again.';

    # user is already logged in
    if ($c->user) {
	$c->log->warn("Already logged in!\n");
	return $c->redirect($c->uri_for('/map'));
    }
    $self->verify_fb_login($c);

    return $c->res->redirect($c->uri_for('/map')) && $c->detach;
}

=head2 registration

    Registers a user for our site, using Facebooks Graph API.

=cut
sub registration :Chained('auth') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $self->register_user($c);
}

=head1 AUTHOR

Raquel Bujans

=head1 COPYRIGHT

Raquel Bujans

=cut

__PACKAGE__->meta->make_immutable;

1;
