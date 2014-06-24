#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use DanceParty::Schema;
use DBIx::Class::DeploymentHandler;
use Config::General;

my %config = new Config::General('danceparty.conf')->getall;
my $connect_info = $config{'Model::DB'}{'connect_info'};
my $schema = DanceParty::Schema->connect(@$connect_info);

my $dh = DBIx::Class::DeploymentHandler->new({ schema => $schema });

#$dh->prepare_version_storage_install;
#$dh->install_version_storage;
#$dh->add_database_version({ version => $s->schema_version });
$dh->deploy({ version => 1 })
