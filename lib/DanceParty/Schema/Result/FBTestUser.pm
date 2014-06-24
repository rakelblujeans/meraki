use utf8;
package DanceParty::Schema::Result::FBTestUser;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;
use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");
__PACKAGE__->table("fbtestuser");
__PACKAGE__->add_columns(
    "fbtestuser_id",
    {
	data_type         => "integer",
	is_auto_increment => 1,
	is_nullable       => 0,
	sequence          => "fbtestuser_fbtestuser_id_seq",
    },
    'user_account_id',     { data_type => 'int',    is_nullable => 0 },
    "token",        { data_type => 'text',   is_nullable => 0 },
    "email",        { data_type => 'text',   is_nullable => 0 },
    "fb_id",           { data_type => 'bigint', is_nullable => 0 },
    "login_url",    { data_type => 'text',   is_nullable => 0 },
    "password",     { data_type => 'text',   is_nullable => 0 }, #TODO hash
    'active',       { data_type => 'bool',   is_nullable => 0 },
    'created_at',   { data_type => 'timestamp',
		    set_on_create => 1, },
    'updated_at',   { data_type => 'timestamp',
		    set_on_update => 1,      is_nullable => 1 },
    );
__PACKAGE__->set_primary_key('fbtestuser_id');
__PACKAGE__->add_unique_constraint(['fb_id']);


__PACKAGE__->belongs_to(
    user_account => 'DanceParty::Schema::Result::UserAccount',
    'user_account_id');

__PACKAGE__->meta->make_immutable;
1;
