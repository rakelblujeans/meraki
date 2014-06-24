use utf8;
package DanceParty::Schema::Result::AuthCredential;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

#
# Currently all credentials come from Facebook
#

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
__PACKAGE__->table("auth_credential");
__PACKAGE__->add_columns(
    'auth_credential_id', 
    { data_type => 'serial', is_auto_increment => 1 },
    'user_account_id',
    { data_type => 'integer', is_nullable => 1 },
    'fb_id',
    { data_type => 'bigint', is_nullable => 1 },
    'token',
    { data_type => 'text', },
    'expires_in',
    { data_type => 'integer', is_nullable => 1 },
    'active', 
    { data_type => 'bool', },
    'created_at',
    { data_type => 'timestamp',
      set_on_create => 1, },
    'updated_at',
    { data_type => 'timestamp',
      set_on_update => 1, is_nullable => 1, },
    );

__PACKAGE__->set_primary_key('auth_credential_id');
__PACKAGE__->add_unique_constraint(['token']);

__PACKAGE__->belongs_to(
    user_account => 'DanceParty::Schema::Result::UserAccount',
    'user_account_id');


__PACKAGE__->meta->make_immutable;
1;

