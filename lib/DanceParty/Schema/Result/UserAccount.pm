use utf8;
package DanceParty::Schema::Result::UserAccount;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
use Perl6::Junction qw/any/;
extends 'DBIx::Class::Core';
use Data::Dumper::Concise;
use LWP::UserAgent;
use JSON::XS;

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");
__PACKAGE__->table("user_account");
__PACKAGE__->add_columns(
    "user_account_id", 
    { data_type => 'serial', is_auto_increment => 1 },
    "email", 
    { data_type => 'text', },
    "username", 
    { data_type => 'text', },
    # Have the 'password' column use a SHA-1 hash and 20-byte salt
    # with RFC 2307 encoding; Generate the 'check_password" method
    'password',
    {
	data_type        => 'text',
	passphrase       => 'rfc2307',
	passphrase_class => 'SaltedDigest',
	passphrase_args  => {
	    algorithm    => 'SHA-1',
	    salt_random  => 20.
	},
	passphrase_check_method => 'check_password',
    },
    "city", 
    { data_type => 'text',
      is_nullable => 1 },
    "lat", 
    { data_type => 'double',
      is_nullable => 1, },
    "lng", 
    { data_type => 'double',
      is_nullable => 1, },
    "active", 
    { data_type => 'bool',
      default_value => 0, },
    "created_at", 
    { data_type => 'timestamp', 
      set_on_create => 1, },
    "updated_at", 
    { data_type => 'timestamp', 
      set_on_update => 1, 
      is_nullable => 1},
    );

__PACKAGE__->set_primary_key('user_account_id');
__PACKAGE__->add_unique_constraint(['email']);

 __PACKAGE__->has_many(
    'user_account_roles' => 'DanceParty::Schema::Result::UserAccountRole',
    'user_account_id'
    );

__PACKAGE__->many_to_many(
    'roles' => 'user_account_roles', 
    'role');

__PACKAGE__->has_many(
    'event_users' => 'DanceParty::Schema::Result::EventUser',
    'user_account_id'
    );

__PACKAGE__->many_to_many(
    'events' => 'event_users',
    'event'
    );

__PACKAGE__->has_many(
    'location_users' => 'DanceParty::Schema::Result::LocationUser',
    'user_account_id'
    );

__PACKAGE__->many_to_many(
    'locations' => 'location_users',
    'location'
    );

__PACKAGE__->has_many(
    'tokens' => 'DanceParty::Schema::Result::AuthCredential',
    'user_account_id',
    );

__PACKAGE__->might_have(
    fbuser => 'DanceParty::Schema::Result::FBTestUser',
    'user_account_id');

sub has_role {
    my ($self, $role) = @_;
    return any(map { $_->role_name } $self->roles) eq $role;
}

sub is_admin {
    my ($self) = @_;
    return $self->has_role('admin') ||
	$self->has_role('super_admin');
}

# There should only be one active token per user
# but in case the active flag is set incorrectly, always
# take the most recent one.
sub active_token {
    my $self = shift;
    my $active_token = return $self->tokens->search(
	{ active => 1 },
	{ order_by => { -desc => 'created_at'},
	  rows => 1 })->single;
    return $active_token;
}

# TODO turn into a db field
sub time_zone {
    my $self = shift;
    my $tz = 'America/New_York';
    return $tz unless ($self->lat && $self->lng);

    my $google_url = 'https://maps.googleapis.com/maps/api/timezone/json?' .
    'location=' . $self->lat .','. $self->lng .
    '&timestamp=' . DateTime->now->epoch .
    '&sensor=false';
    my $ua = new LWP::UserAgent;
    my $response = $ua->get($google_url);
    my $content = $response->content;
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
    my $timezone_info = $coder->decode($content);
    if ($timezone_info && $timezone_info->{'status'} eq 'OK') {
	$tz = $timezone_info->{'timeZoneId'};
    }
    return $tz;
}

__PACKAGE__->meta->make_immutable;
1;
