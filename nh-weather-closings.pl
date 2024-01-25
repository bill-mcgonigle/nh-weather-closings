#!/usr/bin/perl -w
use strict;
use warnings FATAL=>'all';

use LWP::Simple;
use HTML::TreeBuilder;
use Data::Dumper;

my $URL = 'https://www.wmur.com/weather/closings';
my $OUTFILENAME = '/tmp/weather-closings.html';
my @DISTRICTS = ( 'Plainfield','Lebanon School District' );
my $BROWSER = '/usr/bin/chromium';

my ( %closings, @errors );
my $content = '';
my $flastmod = 0;
my $had_today_file = 0;

my $TEMPLATE = <<"EOT";
<html>
<head>
  <title>Weather Closings</title>
  <meta http-equiv="refresh" content="300">
</head>
<body>
 <h1>These closings are in effect</h1>
 <h3>as of: TIMESTAMP :</h3>
CONTENT
</body>
</html>
EOT

my $now = time();
my (undef,$min,$hour,$mday,$mon,$year,$wday,undef,undef) = localtime($now);
$mon += 1;
$year += 1900;

if ( -f $OUTFILENAME ) {
    my @outfilestat = stat($OUTFILENAME);
    $flastmod = $outfilestat[9];
    if ( ( $now - $flastmod ) < 80000 ) {
	$had_today_file = 1;
    }
}


if ( $hour <= 7 || $had_today_file ) {

    my $webpage = get($URL);

    if ( defined( $webpage ) ) {

	my $parser = HTML::TreeBuilder->new();
	my $parse_success = $parser->parse( $webpage );
	$parser->eof();
	
	if ($parse_success) {
	    foreach my $district (@DISTRICTS) {
		my @divs = $parser->find_by_attribute(
		    'data-name', $district
		    );
		if (@divs) {
		    $closings{$district} = ();
		    foreach my $div ( @divs ) {
			my @status_messages = $div->look_down(
			    _tag => 'div',
			    class => 'weather-closings-data-status'
			    );
			foreach my $status (@status_messages) {
			    push(
				@{ $closings{$district} },
				$status->as_text
				);
			}
		    }
		}
	    }
	} else {
	    push(@errors,'Could not parse weatehr closings html.');
	}
	
	$parser->delete;
	
    } else {
	
	push(
	    @errors,
	    'Could not fetch weather closings.'
	    );
	
    }
    
} # before 7 or today_file

if ( @errors ) {

    $content .=
	'<b>Program errors:</b> '.
	join(
	    "<br>",
	    @errors
	)
	;
    
}
    
if ( keys %closings ) {
    
    foreach my $district ( keys %closings ) {
	$content .=
	    '<p>'
	    . '<b>'
	    . $district
	    . '</b>'
	    . join('<br>',@{ $closings{$district} })
	    . '</p>'
	    ;
    }

}

if ( $content eq '' ) {

    if ( $flastmod > 0 ) {
	unlink $OUTFILENAME;
    }
    
} else {

    my $output = $TEMPLATE;
	
    $output =~ s/CONTENT/$content/g;

    my $timestamp = "${hour}:${min} on ${mon}/${mday}";
	
    $output =~ s/TIMESTAMP/$timestamp/g;

    open  OUTFILE, ">${OUTFILENAME}" or die "Can't open > ${OUTFILENAME}: $!";
    print OUTFILE $output;
    close OUTFILE;

    if ( !$had_today_file ) {
	exec($BROWSER,$OUTFILENAME);
    }
}
