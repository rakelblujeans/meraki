package DanceParty::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper::Concise;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

DanceParty::Controller::Root - Root Controller for DanceParty

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

    The root page (/)

=cut

sub index :Path('/') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    # Hello World
    #$c->response->body( $c->welcome_message );
    #$self->_process_status_msgs($c);
}

=head2 default

    Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

    Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;
}

=head2 about
    
    Display info our site's purpose.

=cut
sub about :Chained('/') {
    my ($self, $c) = @_;
    $c->stash(template => 'root/about.tt2');
}

=head2 auto
    
    Check if there is a user and, if not, forward to login page
    
=cut
    
# Note that 'auto' runs after 'begin' but before your actions and that
# 'auto's "chain" (all from application path to most specific class are run)
# See the 'Actions' section of 'Catalyst::Manual::Intro' for more info.
sub auto :Private {
    my ($self, $c) = @_;
    
    # Allow unauthenticated users to reach the login page.  This
    # allows unauthenticated users to reach any action in the Login
    # controller.  To lock it down to a single action, we could use:
    #   if ($c->action eq $c->controller('Login')->action_for('index'))
    # to only allow unauthenticated access to the 'index' action we
    # added above.

    if ($c->controller eq $c->controller('Authentication') 
	|| $c->action eq $c->controller('Map')->action_for('index') 
	|| $c->action eq $c->controller('Root')->action_for('about') 
	#|| $c->action eq $c->controller('Root')->action_for('privacy')
	) {
	return 1;
    }
    
#    my $restricted = ($c->action eq $c->controller('Map')->action_for('add_event') ||
#		      $c->action eq $c->controller('Map')->action_for('add_venue') );
#    unless ($restricted) {
#	return 1;
#    }

    # If a user doesn't exist, force login
    if (!$c->user_exists) {
	# Dump a log message to the development server debug output
	$c->log->debug('***Root::auto User not found, forwarding to /login');
	# Redirect the user to the login page
	$c->response->redirect($c->uri_for('/map'));
	# Return 0 to cancel 'post-auto' processing and prevent use of application
	return 0;
    }
    
    # User found, so return 1 to continue with processing after this 'auto'
    return 1;
}



=head1 AUTHOR

Raquel Bujans

=head1 COPYRIGHT

Raquel Bujans

=cut

__PACKAGE__->meta->make_immutable;

1;
