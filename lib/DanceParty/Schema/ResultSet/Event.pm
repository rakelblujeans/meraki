package DanceParty::Schema::ResultSet::Event;
use strict;
use warnings;
use DateTime::Format::Strptime;
use base 'DBIx::Class::ResultSet';
use Data::Dumper::Concise;
use LWP::UserAgent;
use JSON::XS;

sub find_events {
    my ($self, $search_terms) = @_;
    my %valid_events = ();
    my $events;
    unless ($search_terms && @$search_terms > 0) {
	$events = $self->search( 
	    { start_time => {'>' => DateTime->now } }, 
	    { result_class => 'DBIx::Class::ResultClass::HashRefInflator'} 
	    );
	$self->_add_event($events, \%valid_events);
    } else {
	for my $term (@$search_terms) {
	    $events = $self->search(
		{
		    '-or' => [ artists        => { '-ilike' => $term },
			       organizer_name => { '-ilike' => $term }, 
			       music_genre    => { '-ilike' => $term },
			       name           => { '-ilike' => $term },
			],
		    start_time => {'>' => DateTime->now } 
		}, { result_class => 'DBIx::Class::ResultClass::HashRefInflator'} );
	    $self->_add_event($events, \%valid_events);
	}
    }

    my @final_list;
    while (my ($k, $v) = each %valid_events) {
	push @final_list, $v;
    }
    return \@final_list;
}

sub create_event {
    my ($self, $results, $user) = @_;
    my $locations = $self->result_source->schema->resultset('Location');
    my $events = $self->result_source->schema->resultset('Event');

    my $loc = $locations->find(
        { location_id => $results->{'location_id'} });
    my $time = $results->{'start_time'};

    my $day = substr($results->{'start_day'}, 0, 10);
    my $tz = $self->_get_tz($loc);
    #warn "TZ: $tz [$day] [$time]\n";
    my $strp = DateTime::Format::Strptime->new(
        pattern    => '%F %I:%M %p',
        locale     => 'en_US',
	time_zone  => $tz);
    my $dt_str = $day . ' '. $time;
    my $dt = $strp->parse_datetime($day . ' '. $time);

    die "Invalid start_date\n" unless $dt;
    my $new_event = $events->create(
        { name     => $results->{'name'},
          organizer_name => $results->{'organizer_name'},
          email          => $results->{'email'} || '',
          music_genre    => $results->{'music_genre'},
          artists        => $results->{'artists'},
          start_time     => $dt,
          more_info      => $results->{'more_info'} || '',
          tickets_url    => $results->{'tickets_url'} || '',
	  ticket_price   => $results->{'ticket_price'} || '',
	  privacy        => $results->{'privacy'},
          location_id    => $loc->location_id,
	  active         => 1,
	});
    $new_event->add_to_users($user);
    return $new_event;
}

# Get timezone from location
# use bogus timestamp just so that we can make the call successfully.
# we will use the timestamp correctly when entering into the db.
sub _get_tz {
    my ($self, $loc) =@_;
    my $tz = 'America/New_York';
    return $tz unless ($loc && $loc->lat && $loc->long);

    my $google_url = 'https://maps.googleapis.com/maps/api/timezone/json?' .
	'location=' . $loc->lat . ',' . $loc->long .
	'&timestamp=' . DateTime->now->epoch .
	'&sensor=false';
    my $ua = new LWP::UserAgent;
    my $response = $ua->get($google_url);
    my $content = $response->content;
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
    my $timezone_info = $coder->decode($content);
    #warn "\n\nTIMEZONE INFO:\n" . Dumper $timezone_info;

    if ($timezone_info && $timezone_info->{'status'} eq 'OK') {
	$tz = $timezone_info->{'timeZoneId'};
    }
    #warn "TZ = $tz\n";
    return $tz;
}
sub _add_event {
    my ($self, $events, $event_list) = @_;
    my $location_table = $self->result_source->schema->resultset('Location');
    while (my $event = $events->next) {
	my $loc = $location_table->find(
	    { location_id => $event->{location_id} },
	    { result_class => 'DBIx::Class::ResultClass::HashRefInflator'} 
	    );
	$event->{location} = $loc;
	#$event->{info} = $self->_build_info_($event, $loc);
	$event_list->{$event->{'event_id'}} = $event;
    }
}

sub update_event {
    my ($self, $results, $id) = @_;

    my $time = $results->{'start_time'};
    my $day = substr($results->{'start_day'}, 0, 10);
    my $strp = DateTime::Format::Strptime->new(
        pattern => '%F %I:%M %p',
        locale => 'en_US',
        time_zone => 'America/New_York');
    my $dt = $strp->parse_datetime($day . ' '. $time);
    die "Invalid start_date\n" unless $dt;
    delete $results->{start_day};
    $results->{start_time} = $dt;

    my $event = $self->result_source->schema->resultset('Event')->find(
	{ event_id => $id });
    $event->update($results);
    return $event;
}

1;
