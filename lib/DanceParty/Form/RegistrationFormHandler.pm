package DanceParty::Form::RegistrationFormHandler;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
use HTML::FormHandler::Types (':all');
use Data::Dumper::Concise;
use DateTime::Format::Strptime;

has_field 'signed_request' => ( 
    type => 'Text',
    label => 'signed_request',
    required => 1 );


1;
