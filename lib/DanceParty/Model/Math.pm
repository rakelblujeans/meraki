package DanceParty::Model::Math;
use Moose;
use strict;
use Math::Trig;
use Data::Dumper::Concise;

# Date: 06/23/2012
# Taken from:
# http://www.zipcodeworld.com/samples/distance.pl.html

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#:::                                                                         :::
#:::  This routine calculates the distance between two points (given the     :::
#:::  latitude/longitude of those points). It is being used to calculate     :::
#:::  the distance between two ZIP Codes or Postal Codes using our           :::
#:::  ZIPCodeWorld(TM) and PostalCodeWorld(TM) products.                     :::
#:::                                                                         :::
#:::  Definitions:                                                           :::
#:::    South latitudes are negative, east longitudes are positive           :::
#:::                                                                         :::
#:::  Passed to function:                                                    :::
#:::    lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  :::
#:::    lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  :::
#:::    unit = the unit you desire for results                               :::
#:::           where: 'M' is statute miles                                   :::
#:::                  'K' is kilometers (default)                            :::
#:::                  'N' is nautical miles                                  :::
#:::                                                                         :::
#:::  United States ZIP Code/ Canadian Postal Code databases with latitude   :::
#:::  & longitude are available at http://www.zipcodeworld.com               :::
#:::                                                                         :::
#:::  For enquiries, please contact sales@zipcodeworld.com                   :::
#:::                                                                         :::
#:::  Official Web site: http://www.zipcodeworld.com                         :::
#:::                                                                         :::
#:::  Hexa Software Development Center © All Rights Reserved 2004            :::
#:::                                                                         :::
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub restrict_events_by_user_location {
    my ($self, $user, $events) = @_;
    die 'Missing user' unless $user;
    
    return $self->restrict_events_by_dist($user->lat, $user->lng, $events);
}

sub restrict_events_by_dist {
    my ($self, $src_lat, $src_lng, $events) = @_;
    die 'Missing src_lat' unless $src_lat;
    die 'Missing src_lng' unless $src_lng;
    die 'Missing events' unless $events;

    for (my $idx = 0; $idx < @$events; $idx++) {
	#warn "IDX CURR $idx \n";
	my $event = $events->[$idx];
	my $miles = distance($event->{'location'}{'lat'}, $event->{'location'}{'long'}, $src_lat, $src_lng, 'M');
	#warn "DIST $miles for EVENT: " . $event->{'name'} . "\n";
	if ($miles > 20) {
	    warn "REMOVING " . $event->{'name'};
	    splice(@$events, $idx, 1);
	    $idx--;
	}
    }
    #warn Dumper $events;
    return $events;
}

=head2 distance

 Calculate the distacne between 2 Lat, Long coords

=cut
sub distance {
    my ($lat1, $lon1, $lat2, $lon2, $unit) = @_;
    my $theta = $lon1 - $lon2;
    my $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
    $dist  = acos($dist);
    $dist = rad2deg($dist);
    $dist = $dist * 60 * 1.1515;
    if ($unit eq "K") {
	$dist = $dist * 1.609344;
    } elsif ($unit eq "N") {
	$dist = $dist * 0.8684;
    }
    return ($dist);
}

#print distance(32.9697, -96.80322, 29.46786, -98.53506, "M") . " Miles\n";
#print distance(32.9697, -96.80322, 29.46786, -98.53506, "K") . " Kilometers\n";
#print distance(32.9697, -96.80322, 29.46786, -98.53506, "N") . " Nautical Miles\n";

1;
