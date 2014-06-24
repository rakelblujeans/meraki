package DanceParty::Form::FBLoginFormHandler;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
use HTML::FormHandler::Types (':all');
use Data::Dumper::Concise;
use DateTime::Format::Strptime;

has_field 'expires' => ( 
    type => 'Text',
    label => 'expiry',
    required => 0 );

has_field 'access_token' => (
    type => 'Text',
    label => 'token',
    required => 0 );

has_field 'user_id' => (
    type => 'Text',
    label => 'user_id',
    required => 1 );

1;
