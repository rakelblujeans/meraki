#!/usr/bin/env perl

use strict;
use warnings;
use DanceParty::Schema;

# create from scratch
# By default this will create schema files in the current directory
my $schema = DanceParty::Schema->connect($dsn);
$schema->create_ddl_dir(['MySQL', 'SQLite', 'PostgreSQL'],
                        '2',
                        './dbscriptdir/',
			'1',
    );


# To create ALTER TABLE conversion scripts to update a database to a newer version of your schema at a later point, first set a new $VERSION in your Schema file, then:
