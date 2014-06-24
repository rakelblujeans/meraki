package Facebook;
use Moose;
use strict;
use namespace::autoclean;
use Data::Dumper::Concise;
use MIME::Base64;
use Digest::SHA;
use JSON::XS;
use LWP::UserAgent;
use Config::General;
use Digest::MD5;

=head1 NAME

Facebook - model

=head1 DESCRIPTION

Model encapsulating Facebook communications.

=head1 METHODS

=cut

has 'app_id' => (is => 'ro');
has 'secret' => (is => 'ro');

has 'schema' => (
    is => 'rw',
    required => 1,
    );

has 'user_agent' => (
    is => 'rw',
    default => sub { 
	return new LWP::UserAgent;
    });

has 'coder' => (
    is => 'rw',
    default => sub {
	return JSON::XS->new->ascii->pretty->allow_nonref;	
    });

has 'graph_url' => (
    is => 'ro',
    default => 'https://graph.facebook.com/',
);

=head2 decode_fb_signature

    After registering a user, Facebook returns a MIME encoded response.
    This method decodes it.

=cut
sub decode_fb_signature {
    my ($self, $signed_request) = @_;
    die "Missing signed_request\n" unless $signed_request;

    my ($encoded_sig, $payload) = split('\.', $signed_request); 
    my $sig  = MIME::Base64::decode_base64url($encoded_sig);
    my $data = $self->coder->decode(MIME::Base64::decode_base64url($payload));
    my %decoded = %{ $self->coder->decode(MIME::Base64::decode_base64url($payload)) };
    my $expected_sig = Digest::SHA::hmac_sha256($payload, $self->secret);
    
    my %mydata = ();
    if ($expected_sig eq $sig) {
	while (my ($key, $value) = each %decoded) { 
	    if (ref($value) eq "HASH") {
		while ( my ($key2, $value2) = each(%{$value}) ) {
		    $mydata{"$key-$key2"}=$value2;
		    if (ref($value2) eq "HASH") {
			while ( my ($key3, $value3) = each(%{$value2}) ) {
			    $mydata{"$key-$key2-$key3"}=$value3;
			    #print "$key-$key2-$key3 = $value3\n<br>";
			}}
		    else
		    {
			#print "$key-$key2 = $value2\n<br>";
		    }}}
	    else
	    { 
		
		$mydata{"$key"}=$value;
		#print "$key = $value\n<br>";
	    }}}

    #warn Dumper \%mydata;
    return \%mydata;
}

=head2 exchange_code_for_token

    When FB gives a code and state, use that to request
    a long-term token.

=cut
sub exchange_code_for_token {
    my ($self, $user, $redirect_url, $code, $state) = @_;
    #warn "EXCHANGING CODE FOR TOKEN\n";

    # get app access token from fb
    my $url = $self->graph_url ."oauth/access_token?" .
	"client_id=". $self->app_id .
	"&client_secret=". $self->secret .
	"&code=$code" .
	"&state=$state" .
	"&redirect_uri=$redirect_url";

    # post to fb, get token
    #warn "EXCHANGE CODE FOR TOKEN URL IS: $url \n";
    #warn "STATE IS: $state\n";
    my $response = $self->user_agent->get($url);
    my $content = $response->content;
    #warn "XCHANGE CONTENT: ". Dumper $content;
    my $new_token = substr($content, index($content, 'access_token=') + 13);
    $new_token = substr($new_token, 0, index($new_token, '&'));
    die "new_token not found\n" unless ($new_token);
    my $expires_in = substr($content, index($content, 'expires=') + 8);
    die "expires not found\n" unless ($expires_in);
    #warn "NEW TOKEN: $new_token EXPIRES: $expires_in\n";
    # swap out old token for new
    my $auth_creds = $self->schema->resultset('AuthCredential');
    my $user_tokens = $auth_creds->search({ user_account_id => $user->user_account_id });

    # if there's user tokens on file, deactivate all the old ones and update the
    # expiration date of this token, if listed
    if ($user_tokens->count) {
	$user_tokens->update({ active => 0 });
	my $found = $user_tokens->find({ token => $new_token });
	
	if ( $found ) {
	    #warn "UPDATING EXISTING AUTH TOKEN\n";
	    $found->update(
		{ #token           => $new_token,
		    expires_in      => $expires_in,
		    active          => 1 });
	    return $new_token;
	}
    }

    # otherwise we need to add a new token
    #warn "CREATING NEW AUTH TOKEN\n";
    $auth_creds->create(
	{ token           => $new_token,
	  expires_in      => $expires_in,
	  user_account_id => $user->user_account_id, # TODO why do i have to still do this
	  fb_id           => $user->active_token->fb_id,
	  active          => 1,
	});

    return $new_token;
}

=head2 get_app_access_token

    Request a new access token.

=cut
sub get_app_access_token {
    my ($self) = @_;

    # get app access token
    my $url = $self->graph_url ."oauth/access_token?" .
	"client_id=". $self->app_id .
	"&client_secret=". $self->secret .
	"&grant_type=client_credentials";

    # post to fb, get token
    my $response = $self->user_agent->get($url);
    my $content = $response->content;
    my $app_token = substr($content, index($content, '=') + 1);
    die "app_token not found\n" unless ($app_token);
    return $app_token;
}


=head2 delete_all_test_users

    Delete all test users on FB and delete them from our db.
    Args: app_token

=cut
sub delete_all_test_users {
    my ($self, $app_token) = @_;
    my $ids = $self->_delete_all_test_users_fb($app_token);
    if ($ids) {
	#warn "GOT IDS! " . Dumper $ids;
	$self->_delete_users_db($ids);
    }
}

=head2 _delete_all_test_users_fb
    
    Private method. Request FB deletes all our test users.
    Args: app access token. Will request a new one if none provided.

=cut
sub _delete_all_test_users_fb {
    my ($self, $app_token) = @_;
    #print "Deleting all test users\n";
    my @ids = ();

    $app_token = $self->get_app_access_token() unless $app_token;
    my $url = $self->graph_url . $self->app_id ."/accounts/test-users?access_token=$app_token";
    my $response = $self->user_agent->get($url);
    my $content = $response->content;
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
    my $users = $self->coder->decode($content);
    foreach my $user (@{$users->{'data'}}) {
	#print "\tuser id: " . $user->{'id'} . "\n";
	$self->_delete_user_fb($user->{'id'}, $app_token);
	push @ids, $user->{'id'};
    }
    #print "Done!\n";
    return \@ids;
}

=head2 delete_user

    Deletes a user on fb and deactivates them in our db.

=cut
sub delete_user {
    my ($self, @args) = @_;
    $self->_delete_user_fb(@args);
    $self->_delete_user_db(@args);
}


=head2 _delete_user_fb

    Private method. Request FB deletes a user.
    Args: app access token. Will request a new one if none provided.
    Returns: 1/0
=cut
sub _delete_user_fb {
    my ($self, $user_id, $app_token) = @_;
    die "delete_user_fb: Missing user_id\n" unless $user_id;
    print "Deleting user $user_id\n";
    $app_token = $self->get_app_access_token() unless $app_token;
    my $url = $self->graph_url . $user_id .
	"?method=delete" .
	"&access_token=$app_token";
    my $response = $self->user_agent->post($url);
    my $content = $response->content;
    return ($content eq "true") ? 1: 0;
}

=head2 create_test_user

    Creates a test user on FB and in our db.

=cut
sub create_test_user {
    my ($self, $app_token) = @_;
    my $fbuser = $self->_create_test_user_fb($app_token);
    if ($fbuser) {
	return $self->_create_test_user_db($fbuser);
    }
}

=head2 _create_test_user_fb

    Private method. Request FB creates a test user.
    Args: app access token. Will request a new one if none provided.    
    Returns: fb response

=cut
sub _create_test_user_fb {
    my ($self, $app_token) = @_;
    $app_token = $self->get_app_access_token() unless $app_token;
    my $url = $self->graph_url . $self->app_id ."/accounts/test-users";
    my $args = { installed => 'true',
		 locale => 'en_US',
		 #method => 'post',
		 permissions => "read_stream,user_events,create_event,rsvp_event",
		 access_token => $app_token };
    
    # post to fb, get test user info
    my $response = $self->user_agent->post($url, $args);
    my $content = $response->content;
    my $fbuser = $self->coder->decode($content);
    #warn Dumper $fbuser;

    if ($fbuser->{'error'}) {
	return;
    } else {
	return $fbuser;
    }
}

=head2 event_description

    Generates the event description to be dislayed on an FB event page.
    Note: photo upload not allowed through CLI?
    Arg: event row
    Returns: description string

=cut
sub event_description {
    my ($self, $event) = @_;
    die "event_description: Missing event\n" unless $event;
    my $descrip = "Featuring: ". $event->artists ."\n";
    $descrip = $descrip ."Genres: ". $event->music_genre ."\n";
    $descrip = $descrip ."Artists: ". $event->artists ."\n";
    $descrip = $descrip. "Hosted by: ". $event->organizer_name ."\n";
    $descrip = $descrip . "Cost: " . $event->ticket_price . "\n";
    if ($event->more_info) {
	$descrip = $descrip ."For more info go to ". $event->more_info ."\n";
    }
    if ($event->email) {
	$descrip = $descrip ."Contact us at ". $event->email ."\n";
    }
    if ($event->additional_description) {
	$descrip = $descrip . $event->additional_description . "\n";
    }
    if ($event->tickets_url) {
	$descrip = $descrip . $event->tickets_url . "\n";
    }
    return $descrip;
}

=head2 post_event

    Create a new event on FB and stores the info in our db.
    Args:
    - fbuser: db row
    - new_event: db row
    - fblocation: db row

=cut
sub post_event {
    my ($self, $fbuser, $new_event, $fblocation) = @_;
    my $fb_event = $self->_post_event_fb($fbuser, $new_event, $fblocation);
    if ($fb_event) {
	return $self->_add_fbevent_db($new_event, $fb_event);
    }
}

=head2 _post_event_fb

    Sends our event info to FB.
    Args: 
    - fbuser: db row
    - new_event: db row
    - fblocation: db row
    Returns: fb event response

=cut 
sub _post_event_fb {
    my ($self, $fbuser, $new_event, $fblocation) = @_;
    die "_post_event_fb: Missing fbuser\n" unless $fbuser;
    die "_post_event_fb: Missing new_event\n" unless $new_event;
    #warn "Posting event on FB!!!!" . Dumper $fbuser;

    # re-check fb permissions
#    die 'Missing required permissions' unless $self->_check_permissions($fbuser);

    my $url = $self->graph_url . $fbuser->fb_id . "/events";
    my $dt = $new_event->start_time;
    $dt = $dt->set_time_zone( 'America/New_York' );
    my $dt_str = $dt->datetime . $dt->strftime('%z');

    my %loc = ();
    if ($fblocation) {
	if ($fblocation->id) {
	    $loc{'location_id'} = $fblocation->id;
	} else {
	    $loc{'location'} = $new_event->location->name;
	}
    }

    my $args = { 
	access_token => $fbuser->token, # user access token
	name         => $new_event->name,
	start_time   => $dt_str,
	description  => $self->event_description($new_event),
	privacy_type => $new_event->privacy,
	%loc,
    };

    my $response = $self->user_agent->post($url, $args);
    my $content = $response->content;

    # should return id (string, the new event ID)
    my $event = $self->coder->decode($content);
    #warn Dumper $event;
    if ($event->{'error'}) {
	warn "Failed creating FB event. Details:" . Dumper $event->{'error'};
	return;
    } else {
	return $event;
    }
}

=head2 query_permissions

    Asks FB what permissions our user has.
    Args: fbuser db row
    Returns 1 if user has permissions to create an event, 0 otherwise.

=cut
sub query_permissions {
    my ($self, $fbuser) = @_;
    die "query_permissions: Missing fbuser\n" unless $fbuser;
    my $url = 'https://graph.facebook.com/'. $fbuser->fb_id .'/permissions' .
	"&access_token=" . $fbuser->token;
    my $response = $self->user_agent->get($url);
    my $content = $response->content;
    my $data = $self->coder->decode($content);
    #warn Dumper $content;
    if (!$data->{'error'}) {
#	warn Dumper $data;
	my $perms = $data->{'data'}->[0];
	#warn "LOOKING PERMS: " . Dumper $perms;
	for my $perm (keys %$perms) {
	    if ($perm eq 'create_event' && $perms->{$perm} == 1) {
		return 1;
	    }
	}
    }
    
    return 0;
}

=head2 edit_event

    Sends edited event information to FB and updates our db.

=cut
sub edit_event {
    my ($self, $fbuser, @args) = @_;
    my $success = $self->_edit_event_fb($fbuser, @args);
    if ($success) {
	return $self->_edit_event_db(@args);
    }
}

=head2 _edit_event_fb

    Sends updated event info to FB.
    Note that the name and time cannot be changed if the event is old, 
    or if it has over 5000 attendees.
    Args:
    - fbuser: db row
    - fbevent_id: int
    - updated_fields: hash of fields with changed info
    Returns 0/1.

=cut
sub _edit_event_fb {
    my ($self, $fbuser, $fbevent_id, $updated_fields) = @_;
    die "edit_event_fb: Missing fbuser\n" unless $fbuser;
    die "edit_event_fb: Missing fbevent_id\n" unless $fbevent_id;
    die "edit_event_fb: Missing updated_fields\n" unless $updated_fields;

    # re-check fb permissions
#    die 'Missing required permissions' unless $self->_check_permissions($fbuser,
#	);

    my $url = $self->graph_url . $fbevent_id;
    my $args = { access_token => $fbuser->token,
		 %$updated_fields }; # user access token
    my $response = $self->user_agent->post($url, $args);
    my $success = $response->content;
    if ($success eq 'true') {
	return 1;
    } else {
	warn "Failed editing Facebook event. Details: " . Dumper $success;
	return 0;
    }
}

=head2 delete_event

    Deletes our event on FB and de-activates in our db.
    Args: 
    - fbevent_id: int
    - fbuser: db row
    
=cut
sub delete_event {
    my ($self, $fbevent_id, $fbuser) = @_;
    die "delete_event: Missing fbevent_id\n" unless $fbevent_id;
    die "delete_event: Missing fbuser\n" unless $fbuser;
    my $success = $self->_delete_event_fb($fbevent_id, $fbuser);
    if ($success) {
	return $self->_delete_event_db($fbevent_id);
    }
}

=head2 _delete_event_fb

    Deletes our event on FB.
    Args:
    - fbevent_id: int
    - fbuser: db row
    Returns 0/1.

=cut
sub _delete_event_fb {
    my ($self, $fbevent_id, $fbuser) = @_;
    die "delete_event_fb: Missing fbevent_id\n" unless $fbevent_id;
    die "delete_event_fb: Missing fbuser\n" unless $fbuser;

    # re-check fb permissions
#    die 'Missing required permissions' unless $self->_check_permissions($fbuser);
#
    my $url = $self->graph_url . $fbevent_id .
	"?access_token=". $fbuser->token;
    #my $args = { access_token => $fbuser->token }; # user access token
    #warn "DELETE EVENT URL: $url \n";
    my $response = $self->user_agent->delete($url);
    my $success = $response->content;
    if ($success eq 'true') {
	return 1;
    } else {
	warn "Failed deleting Facebook event. Details: ". Dumper $success;
	return 0;
    }
}

=head2 add_fblocation

    Stores location info in our db. Stores data as is, and stores
    the info FB knows about this location.

=cut
sub add_fblocation {
    my ($self, $fbuser, $location_row) = @_;
    my $fbloc = $self->_add_fblocation_fb($fbuser, $location_row);
    return $self->_add_fblocation_db($location_row, $fbloc) if $fbloc;
}

=head2 _add_fblocation_fb

    Asks FB what it knows about a location.
    Args:
    - fbuser: db row
    - location_row: db row
    Returns: fb response

    Facebook location introspection returns something like:
{
   "name": "1 Front St",
   "is_published": true,
   "location": {
      "street": "1 Front Street",
      "city": "Brooklyn",
      "state": "NY",
      "country": "United States",
      "zip": "11201",
      "latitude": 40.702500875972,
      "longitude": -73.99326871079
   },
   "can_post": true,
   "checkins": 490,
   "were_here_count": 1282,
   "talking_about_count": 1,
   "category": "Local business",
   "id": "105678539491952",
   "link": "https://www.facebook.com/pages/1-Front-St/105678539491952",
   "likes": 76
}

=cut 
sub _add_fblocation_fb {
    my ($self, $fbuser, $location_row) = @_;
    die "location_id: missing fbuser\n" unless $fbuser;
    die "location_id: missing location_row\n" unless $location_row;
    print "[". $location_row->name . "]\n";
    my $response = $self->user_agent->get($self->graph_url .
					  '?access_token='. $fbuser->token .
					  '&q='. $location_row->name .
					  '&type=place'.
					  '&center='. $location_row->lat .','. $location_row->long .
					  '&distance=500');
    my $content = $response->content;
    my $fb_response;
#    try {
#	warn Dumper $content;
	$fb_response = $self->coder->decode($content);
#    } catch {
#	return;
#    };
    my $prefix = "[".$location_row->name .": ". $location_row->address ."]";
    if ($fb_response->{'error'}) {
	warn $prefix ."Failed getting location id. Details:" . Dumper $fb_response->{'error'};
	return;
    } 

    # use the fblocation id to introspect the rest of its properties
    my $place_id = $fb_response->{''}->{data}[0]->{'id'};
    unless ($place_id) {
	print $prefix ." Failed location introspection.\n";
	return;
    }
    my $url = $self->graph_url .$place_id . '?access_token='. $fbuser->token;
    $response = $self->user_agent->get($url);
    $content = $response->content;

    $fb_response = $self->coder->decode($content);
    if ($fb_response->{'error'}) {
	print $prefix ." Failed location introspection. Details: " . Dumper $fb_response->{'error'};
	return;
    } 

    return $fb_response;
}

#-------- Database functions --------------

=head2 _add_fblocation_db

    Private function. Adds FB location info to our db.
    Args:
    - location_row: db row
    - fbplace: fb response
    Returns: new db row

=cut
sub _add_fblocation_db {
    my ($self, $location_row, $fbplace) = @_;
    die "add_location_db: missing location_row\n" unless $location_row;
    die "add_location_db: missing fbplace\n" unless $fbplace;
    
    my $fbloc = $self->schema->resultset('FBLocation')->find(
	{ id => $fbplace->{'id'} });
    return $fbloc if $fbloc;
    my $address = delete $fbplace->{'location'};
    delete $address->{'located_in'} if $address;
    #warn Dumper $address;
    my $website = $fbplace->{'website'};
    my $phone = $fbplace->{'phone'};
    my $link = $fbplace->{'link'};
    $fbloc = $self->schema->resultset('FBLocation')->create(
	{ name => $fbplace->{'name'},
	  is_published => $fbplace->{'is_published'},
	  ($website ? (website => $website) : ()),
	  ($address ? (%$address) : ()),
	  ($phone ? (phone => $phone) : ()),
	  ($link ? (link => $link) : ()),
	  category => $fbplace->{'category'},
	  location_id => $location_row->id,
	  id => $fbplace->{'id'} });
    return $fbloc;
}

=head2 _edit_event_db

    Private function. Updated event info in our db.
    Args:
    - fbevent_id: int
    - updates: fields with new info
    Returns: new db row

=cut
sub _edit_event_db {
    my ($self, $fbevent_id, $updates) = @_;
    die "edit_event_db: missing fbevent_id\n" unless $fbevent_id;
    die "edit_event_db: missing updates\n" unless $updates;
    my $fbevent = $self->schema->resultset('FBEvent')->find(
	{ fb_id => $fbevent_id });
    return unless $fbevent;
    my $event = $fbevent->event;
    $event->update($updates);
    return $event;
}

=head2 _delete_event_db

    Private function. De-activates an event in our db so that it will
    remain hidden from view.
    Args:
    - fbevent_id: int
    Returns: deleted db row #TODO: remove this

=cut
sub _delete_event_db {
    my ($self, $fbevent_id) = @_;
    die "delete_event_db: missing fbevent_id\n" unless $fbevent_id;
    #warn "Deleting FBEVENT ID: $fbevent_id\n";
    my $fbevent = $self->schema->resultset('FBEvent')->find(
	{ fb_id => $fbevent_id });
    $fbevent->update({active => 0}) if $fbevent;
    return $fbevent;
}

=head2 _add_fbevent_db

    Private function. Creates a new db row to hold fb event response info.
    Facebook response looks like: { id => .... }
    Args:
    event: db row
    fbevent: fb response
    Returns: new db row.

=cut
sub _add_fbevent_db {
    my ($self, $event, $fbevent) = @_;
    die "add_fbevent_db: missing event\n" unless $event;
    die "add_fbevent_db: missing fbevent\n" unless $fbevent;
    #warn Dumper $self;
    #warn "FBEVENT: " . Dumper $self->schema;
    my $found = $self->schema->resultset('FBEvent')->find(
	{ fb_id => $fbevent->{'id'} });
    return if $found;
    return $self->schema->resultset('FBEvent')->create(
	{ fb_id => $fbevent->{'id'},
	  event_id => $event->event_id,
	  active => 1
	});
}

=head2 _create_test_user_db

    Private function. Stores fb test user info in our db.
    Args: 
    - fbuser: fb response
    Returns: new db row

    fbuser is the json response from facebook
    Example Facebook response (for insertion into FBTestUser):
{ access_token => "AAABkm922dy4BAD6ytvDZB15ZC0twpAUd4UqJLq7EhjRNRd7aCHG1pG43S6o96lxkVR0lqVAzNCgFZAHZCXQC5xJpZAMu3wRyxI8RGCEpxC6VDZCnmaZAfzD",
  email => "cvvehlb_rosenthalson_1351744299\@tfbnw.net",
  id => "100004604288038",
  login_url => "https://www.facebook.com/platform/test_account_login.php?user_id=100004604288038&n=651ebXV8kpjMo5P",
  password => "1466993306" }

=cut
sub _create_test_user_db {
    my ($self, $fbuser) = @_;
    die "create_test_user_db: missing fbuser\n" unless $fbuser;
    
    # add user info to our db
    my $user = $self->schema->resultset('UserAccount')->create(
	{ username => $fbuser->{'id'},
	  email    => $fbuser->{'email'},
	  password => '{SSHA}'. $fbuser->{'password'}, #TODO properly hash
	  city     => 'Brooklyn, New York',
	  active   => 1,
	});
    my $role = $self->schema->resultset('Role')->find(
	{ role_name => 'regular_user' });
    $user->add_to_roles($role);

    $user->add_to_tokens(
	{ token           => $fbuser->{'access_token'},
	  user_account_id => $user->user_account_id, # TODO why do i have to still do this
	  fb_id           => $fbuser->{'id'},
	  active          => 1,
	});

    $fbuser->{'fb_id'} = delete $fbuser->{'id'};
    $fbuser->{'token'} = delete $fbuser->{'access_token'};
    my $fbuser_db = $self->schema->resultset('FBTestUser')->create(
	{ user_account_id => $user->user_account_id,
	  active          => 1,
	  %$fbuser,
	});

    return $fbuser_db;
}

=head2 _delete_user_db
    
    Private method. Deletes a fb test user in our db.
    Args: 
    - fbuser_id: int
    Return 0/1.

=cut
sub _delete_user_db {
    my ($self, $fbuser_id) = @_;
    #warn "DELETING from DB: " . $fbuser_id . "\n";
    my $fbuser = $self->schema->resultset('FBTestUser')->find(
	{ fbtestuser_id => $fbuser_id });
    return 0 unless $fbuser;
    #warn "FBUSER NOT FOUND\n" unless $fbuser;
    #warn "GOT USER ACOUNT ID : " . Dumper $fbuser->user_account_id . "\n";

    # deleting the user_account cascades to fbtestuser, auth_cred, and role
    $fbuser->user_account->delete;
    return 1;
}

=head2 _delete_users_db
    
    Private method. Shortcut method for deleting multiple fb test
    users from our db at once.
    Args:
    - fb_ids: array of ints. fb_ids are numbers like 100004936603736
    Returns: 1 if successful.

=cut
sub _delete_users_db {
    my ($self, $fb_ids) = @_;
    #warn "FBUSER IDS: " . Dumper $fb_ids;

    my @fbusers = $self->schema->resultset('FBTestUser')->search(
	{ fb_id => { -in => $fb_ids } });
    #warn "\nCOUNT: ". @fbusers;
    unless (@fbusers > 0) {
	return 1;
    }

    foreach my $fbuser (@fbusers) {
	#warn "WE GOT USER_ACCOUNT_ID: " . $fbuser->user_account_id . "\n";
	my $user = $fbuser->user_account;

	# deleting the user_account cascades to fbtestuser, auth_cred, and role
	$user->delete;
    }
    return 1;
}

=head1 AUTHOR

    Raquel Bujans

=head1 COPYRIGHT

    Raquel Bujans

=cut

__PACKAGE__->meta->make_immutable;
1;
