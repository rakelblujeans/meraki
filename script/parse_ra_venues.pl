#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper::Concise;
use Geo::Coder::Google;
use Getopt::Long;
use Config::General;
use FindBin;
use lib "$FindBin::Bin/../lib";
#use DanceParty;
use DanceParty::Model::Facebook;
use DanceParty::Schema;

# Takes in a list of venues copied from residentadvisor.net
# Formats them to our liking
# Outputs the file to ../etc/formated_ra_venues.txt
sub parse_ra_list {
    warn "PARSING\n";
    my %venues = ();
    # we don't want to alter the capitalization of a venue, but
    # we need to prevent duplicates.
    my %venue_names  = (); # all lowercase, for duplicate checking
    open IN_FILE, "<", "etc/venues.txt" or die $!;
    open OUT_FILE, "+>", "etc/formatted_ra_venues.txt" or die $!;
    while (my $in_line = <IN_FILE>) {
	chomp $in_line;
	
	# trim off <option> tags
	my $idx = index($in_line, '>');
	my $new_line = substr($in_line, $idx + 1);
	$idx = index($new_line, '<');
	$new_line = substr($new_line, 0, $idx);

	# separate name from address
	$idx = index($new_line, ' - ');
	my $name = substr($new_line, 0, $idx);
	my $addr = substr($new_line, $idx + 3);
#	warn "$addr\n";

	# remove any "(btween X and Y )"
#	my $open = index("(", $addr);
#	if ($open > -1) {
#	    warn "BEFORE $addr\n";
#	    my $close = index(')', $addr);
#	    if ($close > -1) {
#		$addr = substr($addr, $open + 1, $close - $open + 1);
#	    } else {
#		$addr = substr($addr, $open + 1);
#	    }
#	    warn "AFTER $addr\n";
#	}

	# clean up addresses
	$addr =~ s/\.\.//g;
	$addr =~ s/;/,/g;
	$addr =~ s/located at//ig;
	$addr =~ s/United States$//i;
	$addr =~ s/United State$//i;
	$addr =~ s/United Stat$//i;
	$addr =~ s/United Sta$//i;
	$addr =~ s/United St$//i;
	$addr =~ s/United S$//i;
	$addr =~ s/United $//i;
	$addr =~ s/United$//i;
	$addr =~ s/Unite$//i;
	$addr =~ s/Unit$//i;
	$addr =~ s/Uni$//i;
	$addr =~ s/Un$//i;
	$addr =~ s/U$//i;
	$addr =~ s/ USA$//i;
	$addr =~ s/^\s+//; # trim whitespace
	$addr =~ s/\s+$//;
	$addr =~ s/,$//g; # remove trailing punctuation
#	warn "$addr\n";
	
	unless (defined $venue_names{lc($name)}) {
	    warn "Adding ". lc($name) . "\n";
	    $venues{$name} = $addr; # store in map to weed out duplicates
	    $venue_names{lc($name)} = 1;
	}
    }

    for my $key ( sort keys %venues ) {
	print OUT_FILE "$key : " . $venues{$key} . "\n";
    }

    close IN_FILE or die $!;
    close OUT_FILE or die $!;
}

sub geo_lookup {
    my $conf = new Config::General('danceparty.conf');
    my %config = $conf->getall;
    my $connect_info = $config{'Model::DB'}{'connect_info'};
    my $schema = DanceParty::Schema->connect(@$connect_info);
    my $fb = Facebook->new( schema => $schema,
	       app_id => $config{'Facebook'}{'app_id'},
	       secret => $config{'Facebook'}{'secret'},
        );

    my $app_token = $fb->get_app_access_token();
    $fb->delete_all_test_users($app_token);
    my $fb_test_user = $fb->create_test_user($app_token);

    open IN_FILE, "<", "etc/formatted_ra_venues.txt" or die $!;
    while (my $in_line = <IN_FILE>) {
	chomp $in_line;
	sleep 1;
	my $idx = index($in_line, ' : ');
	my $name = substr($in_line, 0, $idx);
	my $addr = substr($in_line, $idx + 3);

	my $geocoder = Geo::Coder::Google->new(apiver => 3);
	my $geocoded_loc = $geocoder->geocode(
	    location => $addr );
	unless ($geocoded_loc) {
	    print "GEOC NOT FOUND: [$in_line]\n";
	    next;
	}
	my $coords = $geocoded_loc->{'geometry'}{'location'};
	unless ($coords) {
	    print "COORDS NOT FOUND [$in_line]\n";
	    next;
	}
	#print "FOUND: addr\n" . Dumper $coords;

	my $loc_type = $schema->resultset('LocationType')->find(
	    { location_type => 'unlabeled' });
	my $loc_row = $schema->resultset('Location')->find({ name => $name });
	unless ($loc_row) {
	    print "Adding $name to db\n";
	    $loc_row = $schema->resultset('Location')->create(
		{ location_type_id => $loc_type->location_type_id,
		  name    => $name,
		  address => $addr,
		  lat     => $coords->{'lat'},
		  long    => $coords->{'lng'},
		  active  => 1 });
	    $fb->add_fblocation($fb_test_user, $loc_row);
	    $loc_row->add_to_users($fb_test_user->user_account);
	}
    }

    $fb->delete_user($fb_test_user->id);
    print "Done!\n";
}

sub add_fblocations {
    my $conf = new Config::General('danceparty.conf');
    my %config = $conf->getall;
    my $connect_info = $config{'Model::DB'}{'connect_info'};
    my $schema = DanceParty::Schema->connect(@$connect_info);
    my $fb = Facebook->new( schema => $schema,
	       app_id => $config{'Facebook'}{'app_id'},
	       secret => $config{'Facebook'}{'secret'},
        );
    my $fb_test_user = $fb->create_test_user();

    my @locs = $schema->resultset('Location')->all;
    foreach my $loc (@locs) {
	$fb->add_fblocation($fb_test_user, $loc);
    }
}

my ($parse, $geo_lookup, $fblookup);
GetOptions('p|parse' => \$parse,
	   'g|geo_lookup' => \$geo_lookup,
	   'f|facebook_lookup' => \$fblookup);
unless ($parse || $geo_lookup || $fblookup) {
    die "Must supply one argument: -p -g -f\n";
}
#if ($parse && $geo_lookup) {
#    die "Can't specify both -p and -g. Please choose one.\n";
#}

if ($parse) {
    parse_ra_list();
} 
if ($geo_lookup) {
    geo_lookup();
}
if ($fblookup) {
    add_fblocations()
}
