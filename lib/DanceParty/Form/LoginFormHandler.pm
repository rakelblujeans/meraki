package DanceParty::Form::LoginFormHandler;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
use HTML::FormHandler::Types (':all');
use Data::Dumper::Concise;
use DateTime::Format::Strptime;

has_field 'username' => ( 
    type => 'Text',
    label => 'Username',
    minlength => 5,
    required => 1 );

has_field 'password' => (
    type => 'Password',
    label => 'Password',
    minlength => 8,
    ne_username => 'username',
    required => 1 );

has_field 'submit' => ( type => 'Submit' );

1;
