package DanceParty::Form::SearchFormHandler;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
use HTML::FormHandler::Types (':all');

has 'schema' => ( 
    is => 'ro', 
    required => 1
    );

has_field 'submit' => ( type => 'Submit' );

has_field 'search_terms' => (
    type => 'Text',
    minlength => 1,
    maxlength => 100,
    required => 1,
    );

1;
