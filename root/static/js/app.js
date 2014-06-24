var danceparty = {};
(function(context) { 


this.parseErrorMessage = function parseErrorMessage(fieldname, error_msg) {
	console.log('parsing error msg: ' + fieldname);
	if (fieldname) {
		$("<br /><span class=\"error\">*" + error_msg + "</span>").insertAfter('#' + fieldname);
	}
}

this.format_time = function format_time(start_time_str) {
	console.log(start_time_str);
	var date_obj = new Date(start_time_str);
	
	var mins = date_obj.getMinutes();
	if (mins < 10) {
		mins = "0" + mins;
	}

	var hours = date_obj.getUTCHours();
	var am_pm = " AM";
	if (hours > 12) {
		hours = (hours - 12);
		am_pm = " PM";
	}

	var formatted_start = hours + ":" + mins + am_pm + " " + date_obj.toLocaleDateString();
	return formatted_start;
}

this.build_event_listing = function build_event_listing(event, index) {
	var location = event.location;
	var start_time = event.start_time;
	var formatted_start = this.format_time(start_time);

	//console.log(formatted_start);
	var venue = location.name;
	var html =
        '<div itemscope itemtype="http://data-vocabulary.org/Event">' +
        '<span itemprop="description"><div id="ev_name_'+ index + '"><b>' + event.name + "</b></div><br />";
    if (event.more_info) {
        html = html + '<a href="' + event.more_info + '">party info</a><br />';
    }
    html = html + '<b>Party Crew:</b> ' + event.organizer_name + '<br />' +
        '<b>Featuring:</b> '+ event.artists + '<br />' +
        '<b>Genres:</b> ' + event.music_genre + '<br /></span>';
    if (location.url) {
        html = html + '<a itemprop="url" href="'+ location.url +
            '"><span itemprop="location" itemscope ' +
            'itemtype="http://data-vocabulary.org/Organization"><span itemprop="name">' +
            location.name + '</span></span></a>';
    } else {
        html = html + '<span itemprop="location" itemscope ' + 
            'itemtype="http://data-vocabulary.org/Organization"><span itemprop="name">' +
            location.name + '</span></span>';
    }
	html = html + ' - <time itemprop="startDate" datetime="' + formatted_start + '">' +
		formatted_start + '</time><hr />' +
        '<a href="https://maps.google.com/maps?q=' + venue +
        '&ll=' + location.lat + ',' + location.long + '&sll=' +
        location.lat + ',' + location.long +
        '&f=d' +
        '&hq=' + venue + '&t=m&z=14&iwloc=A">Directions</a>' +
	'<span itemprop="geo" itemscope itemtype="http://data-vocabulary.org/Geo">' +
        '<meta itemprop="latitude" content="' + location.lat + '" />' +
        '<meta itemprop="longitude" content="' + location.long + '" /></span>';

    var info =
        'More info: ' + event.more_info + "%0A" +
        'Party crew: ' + event.organizer_name + "%0A" +
        'Featuring: ' + event.artists + "%0A" +
        'Genres: ' + event.music_genre;

    var gcal = ' <a href="http://www.google.com/calendar/event?action=TEMPLATE&text=' +
        event.name +
        '&dates=20120704T020000Z/20120704T080000Z&details=' + info +
        '&location=' + location.name +
        '&trp=false&sprop=www.dancepartynyc.org&sprop=name:DancePartyNYC' + 'target="_blank">Add to GCal</a>';

    html = html + gcal;
    return html;
}

this.refresh_events_listing = function refresh_events_listing(event_idx, js_events) {
		// build up the html for 5 event listings
		var listing_HTML = '';
		for (var i=event_idx; i<event_idx + 5 && i<js_events.length; i++) {
			var ev = js_events[i];
			listing_HTML = listing_HTML + '<li>' + this.build_event_listing(ev, i) + '</li><br />';
		}

		// insert it into the page
		// update next, prev buttons
		$('#events').html('<ul>' + listing_HTML + '</ul>');
		if (event_idx < 5) {
			$('#prev_events').html('');
		} else {
			$('#prev_events').html('<a class="valid_link" href="javascript:void(0)" onclick="refresh_events_listing(' + (event_idx - 5) + '>prev</a>');
		}
		if (event_idx > js_events.length - 5) {
			$('#next_events').hide();
		} else {
			$('#next_events').html('<a class="valid_link" href="javascript:void(0)" onclick="refresh_events_listing(' + (event_idx + 5) + '>next</a>');
		}

		// add the click event which recenters the map
		for (var i=event_idx; i<event_idx + 5 && i<js_events.length; i++) {
			var ev = js_events[i];
			$("#ev_name_" + i).click( function() {
					var newCenter = new google.maps.LatLng(ev.location.lat, ev.location.long);
					gmap.setCenter(newCenter);
				});
		}
};


/*********** GOOGLE MAPS ******************/
this.gmap = null;
this.infoWindow = null;
this.autocentered = 0;
this.geocoder;

this.get_location = function get_location() {
  if (Modernizr.geolocation) {
  	// falls back to default user city (taken from Facebook, or set to NYC by default)
    navigator.geolocation.getCurrentPosition(get_position_successful); //, handle_loc_error);
  } else {
    // no native support
  }
}

// recenter map, update event listings based on position
this.get_position_successful = function get_position_successful(position) {
	if (position && !this.autocentered)
	{
		var latitude = position.coords.latitude;
		var longitude = position.coords.longitude;
		//console.log(position);
		var newCenter = new google.maps.LatLng(latitude, longitude);
		this.gmap.setCenter(newCenter);
		this.autocentered = 1;
		//parse_json_events(;)
	}
}

// fallback to default NYC location
this.handle_loc_error = function handle_loc_error(err) {
	console.log('error getting geo loc');
    if (err.code == 1) {
    	// user said no!
  	}
}

this.placeMarker = function placeMarker(location, map, venue, info) {
	//console.log(map);
  	var marker = new google.maps.Marker({
      position: location,
      map: this.gmap,
      title: venue
  	});
  	this.attachMessage(marker, info);
}


this.attachMessage = function attachMessage(marker, party_info) {
	this.closeInfoWindow();
	this.infoWindow = new google.maps.InfoWindow(
		{ content: party_info,
	      size: new google.maps.Size(50,50)
		});
  	google.maps.event.addListener(marker, 'click', function() {
  	this.infoWindow.open(this.gmap, marker);
  });
}

this.closeInfoWindow = function closeInfoWindow () {
	if (this.infoWindow) {
		this.infoWindow.close();
	}
}

this.showAddress = function showAddress(address) {
	if (this.geocoder) {
		this.geocoder.geocode( 
			{ 'address': address },
			function(results, status) {
				if ( status != google.maps.GeocoderStatus.OK) {
	          		alert("Geocode was not successful for the following reason: " + status);
	            } else {
	            	var location = results[0].geometry.location;
	            	this.gmap.setCenter(location, 13);
					$.ajax({
		        		type: 'POST',
					  	url: 'http://localhost:3000/map/json_events',
					  	data: { 
					  		lat: location.lat(),
					  		lng: location.lng(),
					  	},
					  	success: function(data) {
					  		var js_events = JSON.parse(data.json_events);
							this.parse_events(js_events);		        	
					  	}
					});
	            }
	        }
        );
    }
}
/************** LOGIN *****************/
/*function hideAllForms() {
	$('#map > div[id$="_form"]').hide();
}
function showForm(formName) {
	var formID = '#' + formName;
	if ($(formID).is(":visible")) {
		//console.log('hide ' + formName);
		$(formID).hide();
	} else {
		//console.log('hiding all');
		hideAllForms();
		//console.log('showing ' + formName);
		//console.log( $(formID) );		
		$(formID).show();
	}
}*/

this.showLogin = function showLogin() {
	//console.log("calling showLogin");
	$('#show_login').show();
	$('#show_registration').hide();
	event.preventDefault();
}
this.showRegistration = function showRegistration() {
	//console.log("calling showRegistration");
	$('#show_registration').show();
	$('#show_login').hide();
	event.preventDefault();
}

this.toggleChecked = function toggleChecked(status) {
	$(".checkbox").each( function() {
	$(this).attr("checked",status);
	})
};

this.login = function login() {
	//console.log("LOGIN JS");
    FB.login(function(response) {
        if (response.authResponse) {
            // connected
            testAPI(response.authResponse);
        } else {
            // cancelled
            $('#fb_name').html("");
        }
    });
}

this.testAPI = function testAPI(authResponse) {
    //console.log('Welcome!  Fetching your information.... ');
    FB.api('/me', function(response) {
    	//console.log(authResponse.accessToken);
        //console.log('Good to see you, ' + response.name + '.');
        	});
}

this.parse_events =	function parse_events(js_events) {

		for (var i=0; i<js_events.length; i++) {
			var ev = js_events[i];
		  	this.placeMarker(new google.maps.LatLng(ev.location.lat, ev.location.long), this.gmap,
				ev.location.name, ev.info );
		}
	
		this.refresh_events_listing(0, js_events);
	}
//}();
//}).apply(danceparty);
})(this);