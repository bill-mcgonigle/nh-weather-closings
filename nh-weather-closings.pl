#!/usr/bin/perl -w
use strict;
use warnings FATAL=>'all';

use LWP::Simple;
use HTML::TreeBuilder;

my $DEBUG = 1;

my @DISTRICTS   = (
   'Plainfield',
   'Lebanon School District'
);
my %DATA_SOURCES = (
    'wmur' => {
	'url'          => 'https://www.wmur.com/weather/closings',
	'div_district' => 'weather-closings-data-name',
	'div_data'     => 'weather-closings-data-status',
	},
    );

my $OUTDIR      = '/tmp';
my $OUTFILENAME = 'weather-closings.html';
my $OUTFILE     = $OUTDIR . '/' . $OUTFILENAME;

my $BROWSER               = '/usr/bin/chromium';
my $WINDOW_TITLE          = 'Weather Closings';
my $WINDOW_TITLES_COMMAND = '/usr/bin/xwininfo -tree -root';

my $START_HOUR       = 5;  # A.M. localtime - when to start looking
my $END_HOUR         = 9;  # when to stop everything and close the window
my $CUTOFF_HOUR      = 7;  # when to stop looking unless something was found earlier

my $REFRESH_INTERVAL = 300; # reload the local webpage every this many seconds

my ( %closings, @errors );
my $content = '';
my $flastmod = 0;
my $had_today_file = 0;

my $TEMPLATE = <<"EOT";
<html>
<head>
  <title>${WINDOW_TITLE}</title>
  <meta http-equiv="refresh" content="${REFRESH_INTERVAL}">
  <script type="text/javascript">
    function closeAtEnd() {
      var now = new Date();
      if ( now.getHours() >= ${END_HOUR} ) {
        window.close();
      }
    }
  </script>   
</head>
<body onLoad="javascript:closeAtEnd()">
 <h1>These closings are in effect</h1>
 <h3>as of: TIMESTAMP :</h3>
CONTENT
</body>
</html>
EOT

my $now = time();
my ( undef,$min,$hour,$mday,$mon,$year,$wday,undef,undef ) = localtime( $now );
$mon  += 1;
$year += 1900;

if ( -f $OUTFILE ) {
    debug("Found $OUTFILE");
  my @outfilestat = stat($OUTFILE);
  $flastmod = $outfilestat[9];
  if (
       (
        $now - $flastmod
       )
       < (
	   (
	     24
	     - (
	       $END_HOUR - $START_HOUR
	     )
           )
	   * 3600
         )
     )
      {
	  $had_today_file = 1;
	  debug("$OUTFILE is too old");
  }
}


if ( $hour <= $CUTOFF_HOUR || $had_today_file ) {
    debug("Before cutoff time $CUTOFF_HOUR, proceeding");

    foreach my $data_source (keys %DATA_SOURCES) {
	debug("Fetching $data_source");

	my $webpage = get(
	    $DATA_SOURCES{$data_source}{'url'}
	    );

	if ( defined( $webpage ) ) {
	    debug("Fetch OK");

	    my $parser = HTML::TreeBuilder->new();
	    my $parse_success = $parser->parse( $webpage );
	    $parser->eof();

	    if ($parse_success) {
		debug("Parse OK");
		
		foreach my $district (@DISTRICTS) {
		    debug("Looking for district $district");
		    
		    my @divs = $parser->find_by_attribute(
			$DATA_SOURCES{$data_source}{'div_district'}, $district
			);
		    if (@divs) {
			debug("Found district $district, looking for status");
			
			$closings{$district} = ();
			foreach my $div ( @divs ) {
			    my @status_messages = $div->look_down(
				_tag => 'div',
				class => $DATA_SOURCES{$data_source}{'div_data'}
				);
			    foreach my $status (@status_messages) {
				debug("Found status $status");
				push(
				    @{ $closings{$district} },
				    $status->as_text
				    );
			    }
			}
		    }
		}
	    } else {
		debug("parse failure");
		push(@errors,'Could not parse weather closings html for ' . $data_source . '.');
	    }

	    $parser->delete;

	} else {
	    debug("fetch failure");
	    push(
		@errors,
		'Could not fetch weather closings for ' . $data_source . '.'
		);

	}

    } # each data_source

} # before $CUTOFF_HOUR or today_file

if ( @errors ) {

    $content .=
	'<b>Program errors:</b> '.
	join(
	    "<br>",
	    @errors
	)
	;

}

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

if ( $content eq '' ) {
    debug("content is blank, deleting outfile");
    
    if ( $flastmod > 0 ) {  # save a disk read
	unlink $OUTFILE;
    }

} else {

    my $output = $TEMPLATE;

    $output =~ s/CONTENT/$content/g;

    my $timestamp = "${hour}:${min} on ${mon}/${mday}";

    $output =~ s/TIMESTAMP/$timestamp/g;

    debug("writing output file");
    open  OUTFILE_HANDLE, ">${OUTFILE}" or die "Can't open > ${OUTFILE}: $! wrong owner?";
    print OUTFILE_HANDLE $output;
    close OUTFILE_HANDLE;

    debug("looking for existing window");
    my $window_titles  = `$WINDOW_TITLES_COMMAND`;
    
    my @outfile_titles = grep(
	/$WINDOW_TITLE/,
	$window_titles
	);

    if ( !@outfile_titles ) {
	debug("launching browser");
      exec(
	   $BROWSER,
	   $OUTFILE
	  );
    }

}

sub debug {
    my @debugs = @_;

    if ( $DEBUG ) {
	print STDERR join("\n",@debugs);
	print STDERR "\n";
    }
}

		   
