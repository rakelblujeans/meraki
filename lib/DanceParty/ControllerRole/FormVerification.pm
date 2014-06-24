package DanceParty::ControllerRole::FormVerification;
use MooseX::MethodAttributes::Role;
use Data::Dumper::Concise;
use DanceParty::Form::LoginFormHandler;
use DanceParty::Form::FBLoginFormHandler;
use DanceParty::Form::RegistrationFormHandler;
use namespace::autoclean;

=head1 NAME

DanceParty::ControllerRole::FormVerification

=head1 DESCRIPTION

ControllerRole encapsulating private form helper methods

=head1 METHODS

=cut

=head2 process_form

    Validates submitted form input and stashes errors, if any.
    Args:
    - formname
    - form object
    - [optional]: url to redirect to on error

=cut
sub process_form :Private {
    my ($self, $c, $form_name, $form, $error_action) = @_;
    my $result = $form->process( params => $c->req->params );
    return $self->stash_form_errors($c, $form_name, $form, $error_action);
}

=head2 stash_form_errors

    Stashes all errors as a hash inside the status msg.
    Redirects to a new url, is provided.
    Args:
    - form name
    - form object
    - [optional]: url to redirect to on error

=cut
sub stash_form_errors :Private {
    my ($self, $c, $form_name, $form, $error_action) = @_;
    #$c->log->warn("PROCESSING FORM\n");

    my $errors = {};
    for my $ef ($form->error_fields) {
	for my $err (@{$ef->errors}) {
	    $errors->{$ef->name} = $err;
	}
    }
    $c->log->warn(Dumper $errors);
    if (!$form->validated) {
	#my $url = $error_action || '/map';
	#$c->log->warn("FORM NOT VALIDATED \n");
	my $username = exists $form->fif->{'username'};
	if ($error_action) {
	    return $c->res->redirect(
		$c->uri_for($error_action, ,
			    { mid => $c->set_error_msg($errors),
			      ($username ? (username => $form->fif->{'username'}) : ()),
			      %{$c->req->params} })) # ex: params used when creating event
		&& $c->detach;
	}
    } else {
	#$c->log->warn("FORM VALIDATION SUCCEEDED\n");
	return 1;
    }
}

=head1 AUTHOR

    Raquel Bujans

=head1 COPYRIGHT

    Raquel Bujans

=cut

1;
