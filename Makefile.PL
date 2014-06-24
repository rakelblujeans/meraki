#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'DanceParty';
all_from 'lib/DanceParty.pm';
requires 'Test::Pod::Coverage' => '1.04';
requires 'Catalyst::Runtime' => '5.90012';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::StatusMessage';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Authentication::Realm::SimpleDB';
requires 'Perl6::Junction';
requires 'JSON::XS';
requires 'Log::Log4perl::Catalyst';
requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';
requires 'Geo::Coder::Google';
requires 'HTML::FormHandler::Moose';
requires 'Data::FormValidator';
requires 'Data::FormValidator::Profile';
requires 'Data::FormValidator::Constraints::DateTime';
requires 'Data::FormValidator::EmailValid';
requires 'Data::FormValidator::Filters::HTMLStrip';
requires 'DBIx::Class::TimeStamp';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::DeploymentHandler';
requires 'MIME::Base64';
requires 'DateTime::Format::Pg';
requires 'YAML::XS';
requires 'Mozilla::CA';
requies 'Digest::MD5';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
