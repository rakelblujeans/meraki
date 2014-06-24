package DanceParty::ControllerRole::Auth;
use MooseX::MethodAttributes::Role;
use Data::Dumper::Concise;
use DanceParty::Form::LoginFormHandler;
use DanceParty::Form::FBLoginFormHandler;
use DanceParty::Form::RegistrationFormHandler;
use Geo::Coder::Google;

=head1 NAME

DanceParty::ControllerRole::Auth

=head1 DESCRIPTION

ControllerRole encapsulating private registration/login/permissions logic.

=head1 METHODS

=cut

=head2 _check_authorization

    Checks if a user has permissions to view events/venue area.
    Doesn't do much now, but will once we have more distinct
    roles in place.
=cut
sub _check_authorization :Private {
    my ($self, $c) = @_;
    my $perm = $c->check_user_roles(qw/regular_user/);
    # TODO: clean up roles
    if (!$perm) {
	#warn $c->user->obj->username . "\n";
	#warn "Not authorized to do that!\n";
	my $uri = $c->uri_for('/map', ,
			      {mid => $c->set_error_msg('Not authorized!') });
	return $c->res->redirect($uri) && $c->detach;
    }
}

sub _check_for_admin_permissions {
    my ($self, $c) = @_;
    
    return $c->res->redirect(
	$c->uri_for('/map', ,
		    { mid => $c->set_error_msg(
			  "Invalid login XYZ"),
			  username => $c->user->username,
		    })) 
	&& $c->detach
        unless $c->user->is_admin;
}

=head2 verify_login

    Get the username and password from form
    and validate against our db.

=cut
sub verify_login() :Action {
    my ($self, $c) = @_;

    # validate the user input
    my $form = DanceParty::Form::LoginFormHandler->new();
    if ($self->process_form($c, 'login', $form)) {
	my $fif = $form->fif;
	my $password = $c->req->params->{'password'};
	my $auth_ok = $c->authenticate({ username => $fif->{'username'},
					 password => $password  });
	#$self->_check_for_admin_permissions($c);
	unless ($auth_ok) {
	    $c->log->warn("verify_login failed: ". $fif->{username});
	    # user not found or wrong password provided
	    return $c->res->redirect(
		$c->uri_for('/map', ,
			    { mid => $c->set_error_msg(
				  "Invalid login. Please check your credentials"),
				  username => $fif->{'username'},
				  })) 
		&& $c->detach;
	}
	
	return $auth_ok;
    }
}

=head2 verify_fb_login

    Verify login details with Facebook API.

=cut 
sub verify_fb_login :Action {
    my ($self, $c) = @_;
    #$c->log->warn("VERIFY_FB_LOGIN PARAMS: " . Dumper $c->req->params);
    my $form = DanceParty::Form::FBLoginFormHandler->new();
    my $success = $self->process_form($c, 'fb_login', $form);
    return unless ($success);
    my $fif = $form->fif;
    #$c->log->warn("I GOT THE TOKEN! [" . $fif->{'access_token'} . "]\n");
    
    my $auth_cred = $c->model('DB::AuthCredential')->search(
	{ fb_id => $fif->{'user_id'},
	  active  => 1,
	}, { rows => 1 })->single;
    unless ($auth_cred) {
	$c->log->warn("verify_fb_login error: no auth cred found\n");
	return $c->res->redirect(
	    $c->uri_for('/map', ,
			{ mid => $c->set_error_msg(
			      "User not found!") })) 
	    && $c->detach;
    }

    #$c->log->warn("got auth_cred");
    # if userID and token are valid, log in
    # if userID is valid but token is not, record new token
    if ($auth_cred->token ne $fif->{'access_token'}) {
	#$c->log->warn("updating token");
	#my $coderef = sub {
	    my $new_auth = $auth_cred->copy(
		{ token => $fif->{'access_token'}, 
		  ($fif->{'expires'} ? (expires_in => $fif->{'expires'}) : ()) 
		});
	    $auth_cred->update({ active => 0 });
	#};
	#try {
	#    $c->model('DB')->txn_do( $coderef );
	#} catch { 
	#    $c->log->warn("verify_fb_login error: transaction failed\n");
	#};
    }
    
    #$c->log->warn("Found/updated auth cred. Logging into our site\n");
    my $user = $c->find_user(
	{ username => $auth_cred->user_account->username });
    unless ($user) {
	$c->log->warn("verify_fb_login error: user not found");
	return $c->res->redirect(
	    $c->uri_for('/map', ,
			{ mid => $c->set_error_msg("Error logging in") })) 
	    && $c->detach;
    }
    $c->set_authenticated($user); # logs the user in and calls persist_user
    #$self->_check_for_admin_permissions($c);
    $c->log->warn("verify_fb_login error: blank user\n") unless $c->user;
}

=head2 register_user

    Sign up a new user using Facebook's registration form.

=cut
sub register_user :Private {
    my ($self, $c) = @_;
    my $form = DanceParty::Form::RegistrationFormHandler->new();
    my $success = $self->process_form($c, 'registration', $form);
    return unless ($success);
    my $fif = $form->fif;
    my $results = $c->model('Facebook')->decode_fb_signature(
	$fif->{'signed_request'});

    # look up gps coords
    my $geocoder = Geo::Coder::Google->new(apiver => 3);
    $c->log->warn("register_user error: geocoder is null\n") unless $geocoder;
    #$c->log->warn("NAME: " . $results->{'registration-location-name'});
    my $geocoded_loc = $geocoder->geocode(
	location => $results->{'registration-location-name'} );
    $c->log->warn("register_user error: geocoded loc is null\n") unless $geocoded_loc;
    my $coords = $geocoded_loc->{'geometry'}{'location'};
    $c->log->warn("register_user error: coords are null\n") unless $coords;
    unless ($coords) {
	$coords->{'lat'} = '40.720331';
	$coords->{'lng'} = '-73.952236'; # center on NYC by default  
    }
    # find out if user already exists in our system
    my $exists = $c->model('DB::UserAccount')->find(
	{ username => $results->{'registration-email'} });
    if ($exists) {
	my $uri = $c->uri_for(
	    '/map', , 
	    { mid => $c->set_error_msg("User already registered with this email address\n") });
	return $c->res->redirect($uri) && $c->detach;
    }

    my $new_user = $c->model('DB::UserAccount')->create_user($results, $coords);
    if ($new_user) {
	my $u = $c->find_user({username => $new_user->username });
	$c->set_authenticated($u);
	#$self->_check_for_admin_permissions($c);
	return $c->res->redirect( 
	    $c->uri_for('/map', ,
			{mid => $c->set_status_msg('Thank you for signing up!') }))
	    && $c->detach;
    } else {
	return $c->res->redirect(
	    $c->uri_for('/map', , 
			{ mid => $c->set_error_msg('Creating user failed\n')} )) && $c->detach;
    };
}

=head1 AUTHOR

    Raquel Bujans

=head1 COPYRIGHT

    Raquel Bujans

=cut

1;
