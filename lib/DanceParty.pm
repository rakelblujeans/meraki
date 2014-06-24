package DanceParty;
use Moose;
use namespace::autoclean;
use YAML;
use Log::Log4perl::Catalyst;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    StackTrace
    Authentication
    Authorization::Roles
    Session
    Session::Store::File
    Session::State::Cookie
    StatusMessage
/;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

# set this to 1 to see how this works in STDERR                                                                                                                                                             
my $extra_debug = 0;

after 'setup_components' => sub {
    my $app = shift;
    for (keys %{ $app->components }) {
	warn "Checking for initialize_after_setup  method on: $_" if $extra_debug;
	if($app->components->{$_}->can('initialize_after_setup')){
	    warn "Calling Initialize for for: $_" if $extra_debug;
	    $app->components->{$_}->initialize_after_setup($app);
	}
    }
};

# Configure the application.
#
# Note that settings in danceparty.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

# Start the application
__PACKAGE__->setup();


# Either make Log4perl act like the Catalyst default logger:
#__PACKAGE__->log(Log::Log4perl::Catalyst->new());

# or use a Log4perl configuration file, utilizing the full 
# functionality of Log4perl
__PACKAGE__->log(Log::Log4perl::Catalyst->new('etc/l4p.conf'));

=head1 NAME

DanceParty - Catalyst based application

=head1 SYNOPSIS

    script/danceparty_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<DanceParty::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Raquel Bujans

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
