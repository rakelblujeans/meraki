package DanceParty::Model::Facebook;
use base 'Catalyst::Model';
use Facebook;
use Moose;

our $AUTOLOAD;

#__PACKAGE__->config(
#    app_id => DanceParty->config->{'Facebook'}{'app_id'},
#    secret => DanceParty->config->{'Facebook'}{'secret'},
#);


has 'Facebook' => (
    is => 'rw',
    isa => 'Facebook',
    );

sub initialize_after_setup {
    my ( $self, $app ) = @_;
    $app->log->debug('Initializing Facebook with schema AFTER app is fully loaded...');
    $self->Facebook(
	Facebook->new( schema => $app->model('DB')->schema,
		       app_id => DanceParty->config->{'Facebook'}{'app_id'},
		       secret => DanceParty->config->{'Facebook'}{'secret'},
	));
}

sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    $self->Facebook->$name(@_);
}



1;
