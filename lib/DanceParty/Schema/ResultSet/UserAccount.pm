package DanceParty::Schema::ResultSet::UserAccount;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Data::Dumper::Concise;

sub create_user {
    my ($self, $results, $coords) = @_;
    my $schema = $self->result_source->schema;
    my $coderef = sub {
	my $users = $schema->resultset('UserAccount');
	my $user = $users->create(
	    { username => $results->{'registration-name'},
	      email    => $results->{'registration-email'},
	      password => $results->{'registration-password'},
	      city     => $results->{'registration-location-name'},
	      lat      => $coords->{'lat'} || '',
	      lng      => $coords->{'lng'} || '',
	      active   => 1,
	    });
	
	my $role = $schema->resultset('Role')->find(
	    { role_name => 'regular_user' });
	$user->add_to_roles($role);

	#$schema->resultset('AuthCredential')->create(	
	$user->add_to_tokens(
	    #$user->add_to_fbuser
	    { user_account_id => $user->user_account_id,
	      token         => $results->{'oauth_token'}, 
	      fb_id         => $results->{'user_id'},
	      expires_in    => $results->{'expires'},
	      active        => 1,
	    });
	return $user;
    };

    try {
	return $schema->txn_do( $coderef );
    } catch {
	return;
    };
}


1;
