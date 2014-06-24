package DanceParty::ControllerRole::FacebookPermissions;
use MooseX::MethodAttributes::Role;
use Data::Dumper::Concise;
use namespace::autoclean;
#use Digest::MD5 qw(md5);

=head1 NAME

DanceParty::ControllerRole::FacebookPermissions

=head1 DESCRIPTION

ControllerRole encapsulating private oauth functionality.

=head1 METHODS

=cut

=head2 request_permissions

    Requests permissions as setup in our app settings on facebook.com

=cut
sub request_permissions :Private {
    my ($self, $c, $redirect_url) = @_;
    $c->stash(template => 'events/index.tt2');
    # otherwise permissions were not granted
    #$c->log->warn("FB permissions have not been granted, prompting user...\n");
    
    my $dialog_url= "https://www.facebook.com/dialog/oauth?".
	"client_id=" . $c->model('Facebook')->app_id .
	"&state=" . DateTime->now->epoch . 
	"&scope=create_event,rsvp_event,user_events,publish_actions,email".
	"&redirect_uri=$redirect_url";
    #$c->log->warn("PERMS DIALOG URL: [$dialog_url] \n");
    return $c->res->redirect($dialog_url);
}


=head2 exchange_code_for_token

    Exchange 1hr temp token for a 60day one.

=cut
sub exchange_code_for_token :Private {
    my ($self, $c, $redirect_url) = @_;
    #$c->log->warn("IN CONTROLLER ROLE REDIRECT URL: $redirect_url\n");
    my $code = $c->req->params->{'code'};
    my $state = $c->req->params->{'state'};
    
    # TODO: form verification

    # trade 
    my $new_token = $c->model('Facebook')->exchange_code_for_token(
	$c->user, $redirect_url, $code, $state);
    #$c->log->warn("RETURNED NEW TOKEN: $new_token \n");
}

=head1 AUTHOR

    Raquel Bujans

=head1 COPYRIGHT

    Raquel Bujans

=cut

1
