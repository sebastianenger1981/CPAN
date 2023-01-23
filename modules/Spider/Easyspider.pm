#!/usr/bin/perl

package Spider::Easyspider;
$VERSION = '1.98';

require "Spider\\HtmlParser.pl";
use WWW::RobotRules;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request;
use Spider::Parser;
use LWP::Simple;

my $IS_BACKUPED = "0";

########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class) = @_;
	my $object = bless {}, $class;
	return $object;

}; #sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende


########### Subroutine zur Bestimmung der aktuellen Zeit:  Start
# Aufgabe: _getFullTime() - bestimme aktuelle zeit
# Rückgabe: "$mday.$mon.$year $hour:$min:$sec"

sub _getFullTime(){

	my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
	my $year = $year + 1900;
	my $mon = $mon + 1;
	return "$mday.$mon.$year $hour:$min:$sec";

}; # sub _getFullTime(){}
########### Subroutine zur Bestimmung der aktuellen Zeit:  ENDE


########### Subroutine zur Bestimmung des Hostnames:  Start
# Aufgabe: &get_hostname() - bestimme hostname
# Rückgabe: Hostname der form www.HOST.de

sub get_hostname() {
	
	my ($self, $url) = @_;
	my @host = split('/', $url);
	return @host[2];	

}; # sub get_hostname() { }
########### Subroutine zur Bestimmung des Hostnames:  ENDE


############ Subroutine zur Bestimmung der Gleichheit zwischen Starurl und $url: Start
# Aufgabe: &is_same_host() - bestimme gleichheit für starturl und url
# Rückgabe: gleichheitswert
# TODO: eventuelle jede if anweisung mit einem eigenen else {} versehen

sub is_same_host() {

	my ($self, $org, $comp) = @_;
	
	@1		= split('/',$org);
	@2		= split('/',$comp);
	
#	if (@1[0] eq @2[0]){
#		if (@1[1] eq @2[1]){
#			if (@1[3] eq @2[3]){
#				return 1;
#			};
#		};
#	} else {
#		return 0;
#	};

	if (@1[2] eq @2[2]){
		return 1;
	} else {
		return 0;
	};

}; #	sub is_same_host() {}
############ Subroutine zur Bestimmung der Gleichheit zwischen Starurl und $url: Ende


############ Subroutine zur Berechnung der Verzeichnistiefe: Start
# Aufgabe: &verzeichnistiefe - berechne verzeichnistiefe für übergebenen link
# Rückgabe: Verzeichnistiefe wert

sub verzeichnistiefe() {

	my ($self, $url)  = @_;
	my @host = split('/', $url);
	my $count = -1;		# stimmt so!
	
	for ($i = 2; $i <= $#host; $i++){
		$count++;
	}
	
	if ($count >= "0") {
		return $count;
	} elsif ($count < "0") {
		return 0;
	}

}; # sub berechne_verzeichnistiefe() {} 
############ Subroutine zur Berechnung der Verzeichnistiefe: Ende

########### Subroutine zum Auslesen der Region Tags aus dem HTML CODE des gescannten Dokumentes:  Start
# Aufgabe: &get_region_information() - bestimme region informationen
# Rückgabe: Hostname der form www.HOST.de

sub get_region_information() {
	
	my ($self, $region_tag, $html_code ) = @_;
	chomp($region_tag);
	return "EMPTY REGION FIELD" if ($region_tag eq '');
	return "EMPTY REGION FIELD" if ($region_tag eq 'undef');
	my @region = $html_code =~ /<$region_tag.*?>(.*?)<\/$region_tag>/gis;
	my $regionref = \@region;
	return &HtmlParser($regionref);
	
}; # sub &get_region_information() {}
########### Subroutine zum Auslesen der Region Tags aus dem HTML CODE des gescannten Dokumentes:   ENDE

########### Subroutine zur Extrahierung des Body Tags: Start
# Aufgabe: gib html content des bodys zurück, dokument wird als parameter übergeben
# Rückgabe: @body mit body informationen, als txt formatiert!

sub get_body() {

	my ($self, $page) = @_;
	my @body = $page =~ /<body.*?>(.*?)<\/body>/gis;
	my $bodyref = \@body;
	return &HtmlParser($bodyref);

};
########### Subroutine zur Extrahierung des Title Tags: Ende

########### Subroutine zur Extrahierung des Title Tags: Start
# Aufgabe: gib title des dokumentes zurück, dokument wird als parameter übergeben
# Rückgabe: @title mit title informationen

sub get_title() {

	my ($self, $page) = @_;
	my @title = $page =~ /<title>(.*?)<\/title>/gis;
	return @title;
	
};
########### Subroutine zur Extrahierung des Title Tags: Ende


############# Subroutine zur Extrahierung von Links: Start
# Aufgabe: &get_links - extrahiere links aus übergebenen html datenstrom 
# Rückgabe: @links mit Links aus übergebenen html datenstrom

sub get_links() {
	
	my ($self, $page, $starturl) = @_;
	my @content = split('a href', $page);
	my $frame = "0";
	
	chomp($starturl);
	
	foreach $line (@content){
		my ($tmp,$link,undef) = split('"', $line);
		next if ($link =~ /mailto/);
		
		# wenn es sich bei einer url um eine relative url handelt, wandle es mit make_absolute_url um!	
		if ($link !~ /^http/){
			next if ($tmp =~ /</i);
			my $abs_link = &make_absolute_url($starturl, $link);
			push(@links, $abs_link);
		} else {
			push(@links, $link);
		};
	};

	undef @content;
	# @links = grep { ! $seen{$_} ++ } @links;
	
	if (defined(@links)){
		
		return @links;
		
	} else {
		
		my @content2 = split('\'', $page);
		my @frame_content = split('<', $page);
	
		foreach $frame_line (@frame_content){
			($tmp,$link,undef) = split('"', $frame_line);
			if ($tmp =~ /FRAME SRC/i){
				push(@links2, $link);
				$frame = "1";
			};
		};
		
		undef @frame_content;
		
		if ($frame == "0") {
		
			foreach $line (@content2){
		
				my ($tmp,$link,undef) = split('"', $line);
				next if ($link =~ /mailto/);
		
				if ($link !~ /^http/){
					next if ($tmp =~ /</i);
					my $abs_link = &make_absolute_url($starturl, $link);
					push(@links2, $abs_link);
				} else {
					push(@links2, $link);
				};
			};
			
		};
		
		undef @content2, $frame;
		#@links2 = grep { ! $seen2{$_} ++ } @links2;
		return @links2;
	};

}; # sub get_links {}
############# Subroutine zur Extrahierung von Links: Ende   


################### Subroutine zum Umwandeln von relativen in absolute Urls: Start
# Aufgabe: &make_absolute_url() - relativ->absolute urls umwandeln
# Rückgabe: umgewandelte Url

sub make_absolute_url() {

 	my ($parent_url, $child_url) = (shift,shift);
		
	my $parent_bak = $parent_url;
		
	if ($child_url =~/^#/){
		return undef;
	};
	
	my $hack;
	if ($child_url =~ m|^/|) {
		$parent_url =~ s|^(http://[\w.]+)?/.*$|$1|i;
		return $parent_url.$child_url;
	};

	if ($child_url =~ m|^\.\.\/|i){
		$parent_url =~ s/\/[^\/|^~]+$//; # Strip filename (fix: DL)
		if ($parent_url =~ /\/$/){$parent_url =~ s/\/$//;}	# (DL)
		if ($child_url =~ /^\.\//){$child_url =~ s/^\.\///;}	# (DL)
		while ($child_url=~s/^\.\.\///gs ){
			$parent_url =~s/[^\/]+\/?$//;
		}
		$child_url = $parent_url.$child_url;

#	} elsif ($child_url =~ m|^\./|i) {
#	
#		substr($child_url,0,1) = "";
#		$child_url = $parent_bak .'/'. $child_url;
		
	} elsif ($child_url !~ m/^http:\/\//i){
		
		# Assume relative path needs dir
		$parent_url =~ s/\/[^\/]+$//;	# Strip filename
		if ($parent_url =~ /\/$/){ chop $parent_url }
		$child_url = $parent_url .'/'.$child_url;
	}; 
	
	my $child_bak = $child_url;
	substr($child_bak, 0,6) = "";
	
	if ( $child_bak =~ /^\// ){
		#	print "FALSE: $child_bak\n";

	} else {
		#print "RIGHT: $child_bak\n";
		$child_url = $parent_bak .'/'. $child_bak;
	};
	
	return $child_url;

}# sub make_absolute_url {}
################### Subroutine zum Umwandeln von relativen in absolute Urls: Ende

############# Subroutine zum Extrahieren der Metakeys: Start
# Aufgabe: &get_metakeys - extrahiere metakeys aus übergebenen html datenstrom und gib ergebniss als hash zurück
# Rückgabe: %meta mit metakey informationen

sub get_metakeys() {

	my ($self, $content) = @_;
   
	my @content_lines	= split( "\n", $content );     # let's make a gigantic string with all the
	my $single_line		= join( "", @content_lines );   # lines of HTML on one line. Come on, it'll be fun
	my %meta;

	# rückgabe der Metakey informationen in grossbuchstaben

	# <meta name = "name" content = "content" \>
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+name\s*=\s*"([^"]+)"\s*content\s*=\s*"([^"]+)"\s*\/>/gi;
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+name\s*=\s*"([^"]+)"\s*content\s*=\s*"([^"]+)"\s*>/gi;
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+content\s*=\s*"([^"]+)"\s*content\s*=\s*"([^"]+)"\s*>/gi;

	# <meta name = 'name' content = 'content' \>
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+name\s*=\s*'([^']+)'\s*content\s*=\s*'([^']+)'\s*\/>/gi;
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+name\s*=\s*'([^']+)'\s*content\s*=\s*'([^']+)'\s*>/gi;

	# <meta http-equiv = "name" content = "content" \>
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+http-equiv\s*=\s*"([^"]+)"\s*content=\s*"([^"]+)"\s*\/>/gi;
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+http-equiv\s*=\s*"([^"]+)"\s*content=\s*"([^"]+)"\s*>/gi;

	# <meta http-equiv = 'name' content = 'content' \>
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+http-equiv\s*=\s*'([^']+)'\s*content=\s*'([^']+)'\s*\/>/gi;
	$meta{uc($1)} = $2 while  $single_line =~ m/<\s*meta\s+http-equiv\s*=\s*'([^']+)'\s*content=\s*'([^']+)'\s*>/gi;

	# <meta content = "content" name = "name" \>
	$meta{uc($2)} = $1 while  $single_line =~ m/<\s*meta\s+content\s*=\s*"([^"]+)"\s*name\s*=\s*"([^"]+)"\s*\/>/gi;
	$meta{uc($2)} = $1 while  $single_line =~ m/<\s*meta\s+content\s*=\s*"([^"]+)"\s*name\s*=\s*"([^"]+)"\s*>/gi;
	
	# <meta content = 'content' name = 'name' \>
	$meta{uc($2)} = $1 while  $single_line =~ m/<\s*meta\s+content\s*=\s*'([^']+)'\s*name\s*=\s*'([^']+)'\s*\/>/gi;
	$meta{uc($2)} = $1 while  $single_line =~ m/<\s*meta\s+content\s*=\s*'([^']+)'\s*name\s*=\s*'([^']+)'\s*>/gi;

	return %meta;
	
} # sub get_metakeys() {
############# Subroutine zum Extrahieren der Metakeys: Ende


############# Subroutine zur Bestimmung der Dateiendung: Start
# Aufgabe: &_FileType - gib dateiendung der übergebenen url zurück
# Rückgabe: string mit dateiendung

sub _FileType(){

	my $url			= shift;
	my @filestuff	= split('\.', $filename);
	my $filetype	= lc($filestuff[$#filestuff]);

	if ( $filetype !~ /(pdf|doc|xml|htm|php|phps|asp|aspx|rtf|xls|ppt|rss)$/i ) {
		$filetype	= "unknown";
	};

	return $filetype;

}; # sub _FileType(){ }
############# Subroutine zur Bestimmung der Dateiendung: Ende


############# Subroutine zum holen und parsen der robots.txt:Start
# Aufgabe: & robot_rules() - erstelle http request und hole robots.txt für anschließendes parsing
# Rückgabe: objektreferenz auf rules

sub robot_rules() {

	my $url		= shift;

	my $rules	= WWW::RobotRules->new('Easy-Spider.com - robots.txt Parser/1.0');
	$url		= $url . "/robots.txt";
	my $robots	= get($url);
	$rules->parse( $url, $robots) if defined $robots;
	return $rules if defined $rules;

}; # sub robot_rules() {
############# Subroutine zum holen und parsen der robots.txt: Ende


############# Subroutine zum erstellen eines HTTP Requestes:Start
# Aufgabe: &http_get - erstelle und sende http request an übergebene url
# Rückgabe: content der angefragten uri/url

sub http_get() {
	
	my $self		= shift;
	my $url			= shift;
	my $timeout		= shift;
	my $useragent	= shift;
	my $ProxyCFG	= shift;

	my $UA			= LWP::UserAgent->new( keep_alive => 1 );

	$UA->agent( $useragent );
	$UA->timeout( $timeout );
	$UA->max_size(95000000);	# no limit in how big the page can be

	if ( %{$ProxyCFG}->{"USEPROXY"} == 1 ) {
		$UA->proxy(['http', 'ftp'] => %{$ProxyCFG}->{"PROXYURL"});
	};

	my $jar_jar = HTTP::Cookies->new
		( file => "$ENV{HOME}/.SpiderCookies.txt" || ".SpiderCookies.txt",
			autosave => 1,
			max_cookie_size => 40960,
			max_cookies_per_domain => 10000, );
			$UA->cookie_jar( $jar_jar );

	my $req = HTTP::Request->new(GET => $url);

	if ( %{$ProxyCFG}->{"USEPROXY"} == 1 ) {
		$req->proxy_authorization_basic( %{$ProxyCFG}->{"PROXYUSER"}, %{$ProxyCFG}->{"PROXYPASS"});
	};

	# Pass request to the user agent and get a response back
  	my $res = $UA->request($req);

	if ($res->is_success) {
		
		my $type = $res->content_type;
		my $cont = $res->content;
		my $Content = {
				"type"		=> $type,
				"content"	=> $cont,
		};
		return $Content;

  	} else {

		my $type = $res->content_type;
		my $Content = {
				"type"		=> $type,
				"content"	=> "<html><body> Spider::Easyspider::http_get(): " . $res->status_line . "</body></html>",
		};
		return $Content;

   	};

}; # sub http_get {}
############# Subroutine zum erstellen eines HTTP Requestes:Ende


############ Subroutine zur Bearbeitung der Linktiefe, kann nicht als OO implementiert werden -> zu großer aufwand
# Aufgabe: &scanner: Scanne starturl von linktiefe 0 bis $depth, folge externen links /(nicht) 
# Rückgabe: 1

sub scanner() {

	my $self			= shift; 
	my $ConfigHashRef	= shift;
	my %SCANNER_CONFIG	= %{$ConfigHashRef};
	
	my @SCANNED_URL		= ();
	my $StatusHashRef	= {};
	my @working_links	= ();

	my $ProxyCFG = {
		"USEPROXY"	=> %SCANNER_CONFIG->{"USEPROXY"},
		"PROXYURL"	=> %SCANNER_CONFIG->{"PROXYURL"},
		"PROXYUSER"	=> %SCANNER_CONFIG->{"PROXYUSER"},
		"PROXYPASS"	=> %SCANNER_CONFIG->{"PROXYPASS"},
	};
				
	my $use_robots		= %SCANNER_CONFIG->{"ROBOTS"};
	my $HTMLHASHREF		= %SCANNER_CONFIG->{"OBJECT"}->http_get( %SCANNER_CONFIG->{"URL"}, %SCANNER_CONFIG->{"TIMEOUT"}, %SCANNER_CONFIG->{"USERAGENT"}, $ProxyCFG );
	my @LINKS 			= %SCANNER_CONFIG->{"OBJECT"}->get_links( %{$HTMLHASHREF}->{'content'} , %SCANNER_CONFIG->{"URL"} );
	my %METAKEYS 		= %SCANNER_CONFIG->{"OBJECT"}->get_metakeys( %{$HTMLHASHREF}->{'content'} );
	my $TITLE 			= %SCANNER_CONFIG->{"OBJECT"}->get_title( %{$HTMLHASHREF}->{'content'} );
	my $BODY 			= %SCANNER_CONFIG->{"OBJECT"}->get_body( %{$HTMLHASHREF}->{'content'} );	

	my $HOSTNAME		= %SCANNER_CONFIG->{"OBJECT"}->get_hostname( %SCANNER_CONFIG->{"URL"} );
	my $PDE_URL			= %SCANNER_CONFIG->{"OBJECT"}->verzeichnistiefe( %SCANNER_CONFIG->{"URL"} );	# pfadtiefe für $URL bestimmen
   
  	push( @working_links, "$PDE_URL " . %SCANNER_CONFIG->{"URL"} );		# erste url den zu suchenden infos hinzufügen

	foreach $link (@LINKS) {
		push( @working_links, "0 $link" );
	};
	
	# free memory
	@LINKS = (); 

	my $ROBOTRULES_OBJ	= &robot_rules( %SCANNER_CONFIG->{"URL"} );		# parse robots text

	# anweisung, die für alle links der jeweiligen linktiefe den aktuellen link abarbeitet
	for ( $CURRENTDEPTH = 0; $CURRENTDEPTH <= %SCANNER_CONFIG->{"LINKDEPTH"}; $CURRENTDEPTH++ ) {
	
	SCANNELINKS: 
		$LINKCOUNT++;
		foreach $working_link (@working_links){
			
			# splitte die einträge auf in [INT] [URL]
			my ($tmp_depth, $tmp_url) = split(' ', $working_link);

			if ( defined($ROBOTRULES_OBJ) && ( $use_robots == 1 ) ) {
				if( $ROBOTRULES_OBJ->allowed( $tmp_url ) ) {
					# simply go on with scanning	
				} else {
					# otherwise skip a non-allowd link
					next SCANNELINKS;
				};
			};

			# bestimme die gleichheit der zwei urls
			my $is_same = %SCANNER_CONFIG->{"OBJECT"}->is_same_host( %SCANNER_CONFIG->{"URL"} , $tmp_url);
			
			# bestimme die verzeichnistiefe / pagedepth für aktuelle url
			my $verzeichnistiefe = %SCANNER_CONFIG->{"OBJECT"}->verzeichnistiefe( $tmp_url );
			
			# wenn die anzahl der bereits gescannten link den wert der max zu scannenden links überschreitet 
			if ( %SCANNER_CONFIG->{"CRAWLPAGES"} == $LINKCOUNT ) {
				
				print "Maximum number of links to scan reached [link depth]- exiting!\n";

				# trick: wenn die max anzahl zu scannender links überstiegen ist, beende die routine mit return
				if ( %SCANNER_CONFIG->{"OS"} eq lc("windows") ) {
					return %SCANNER_CONFIG->{"STOREPATH"} ."\\$HOSTNAME";
				} else {
					return %SCANNER_CONFIG->{"STOREPATH"} ."/$HOSTNAME";
				};
			
			}; # if ( $CRAWLPAGES == $LINKCOUNT ) { }
			
			# %SCANNER_CONFIG->{"PATHDEPTH"} = {externer wert aus der konfig} / $verzeichnistiefe = {intern berechneter verzeichnistiefewert für aktuelle url}
			if ( $verzeichnistiefe > %SCANNER_CONFIG->{"PATHDEPTH"} ) {

				print "$verzeichnistiefe > " . %SCANNER_CONFIG->{"PATHDEPTH"} . " für $tmp_url\n";
				print "Maximum number of links to scan reached [page depth] - exiting!\n";
				sleep 1;

				# überspringe links die, nicht den og kriterien entsprechen
				next SCANNELINKS;

			};

			# dont follow foreign links
			if ( ($follow_flag == "0") && ($is_same == "1") ) { 
				
				next if ($tmp_url =~ /javascript/);
				
				if ( $tmp_url =~ /^http/i ) {
				} elsif ( $tmp_url =~ /^https/i ) {
				} elsif ( $tmp_url =~ /^ftp/i ) {	
				} else {
					$tmp_url = "http://" . $tmp_url;
				};
	
				# überspringe bereits gescannte urls
				foreach $scanned_link (@SCANNED_URL) {
					if ( $scanned_link eq $tmp_url ) {
						next SCANNELINKS;
					};
				};	
			
				print _getFullTime() . " [Link: $LINKCOUNT][Depth: $CURRENTDEPTH] Scanning $tmp_url\n";
	
				my $hashref = { "filetype"	=> &_FileType( $tmp_url ) };
				$StatusHashRef{$tmp_url} = $hashref;
			
				# hole referenz des rückgegebenen arrays @links
				$LINK_ARRAYREF_SUB = %SCANNER_CONFIG->{"OBJECT"}->sub_scanner( $ConfigHashRef, $StatusHashRef{$tmp_url}, $tmp_url );	
				delete $StatusHashRef{$tmp_url};

				# speichere alle urls, die schon gescannt wurden -> speicherverbrauch bei sehr viel gescannten urls
				push( @SCANNED_URL, "$tmp_url" );
				push( @working_links, @{$LINK_ARRAYREF_SUB} );
				
			# if we should follow foreign links
			} elsif ( $follow_flag == "1" ) { 

				next if ($tmp_url =~ /javascript/);
				
				if ( $tmp_url =~ /^http/i ) {
				} elsif ( $tmp_url =~ /^https/i ) {
				} elsif ( $tmp_url =~ /^ftp/i ) {	
				} else {
					$tmp_url = "http://" . $tmp_url;
				};
				
				# überspringe bereits gescannte urls
				foreach $scanned_link (@SCANNED_URL) {
					if ($scanned_link eq $tmp_url) {
						next SCANNELINKS;
					};
				};	
				# $LINKCOUNT++;
				print _getFullTime() . " [Link: $LINKCOUNT][Depth: $CURRENTDEPTH] Scanning $tmp_url\n";

				my $hashref = { "filetype"	=> &_FileType( $tmp_url ) };
				$StatusHashRef{$tmp_url} = $hashref;
			
				# hole referenz des rückgegebenen arrays @links
				$LINK_ARRAYREF_SUB = %SCANNER_CONFIG->{"OBJECT"}->sub_scanner( $ConfigHashRef, $StatusHashRef{$tmp_url}, $tmp_url );
				delete $StatusHashRef{$tmp_url};

				# speichere alle urls, die schon gescannt wurden -> speicherverbrauch bei sehr viel gescannten urls
				push( @SCANNED_URL, "$tmp_url" );	# removed "$tmp_url\n"
				push( @working_links, @{$LINK_ARRAYREF_SUB} );
				
			#	wenn FOLLOWEXT = 0 und die $tmp_url eine rechnerfremde url ist, dann bekommt man hier meldungen
			#	} else {
			#	print "$is_same : ($starturl, $tmp_url) : URL MISMATCH: $tmp_url\n";
			}; # 
			
		}; # foreach $working_link (@working_links){}

	}; # for ($CURRENTDEPTH = 0; $CURRENTDEPTH <= $LINKDEPTH; $CURRENTDEPTH++) {
 
	if ( lc( %SCANNER_CONFIG->{"OS"} ) eq "windows" ) {
		return %SCANNER_CONFIG->{"STOREPATH"} ."\\$HOSTNAME";
	} else {
		return %SCANNER_CONFIG->{"STOREPATH"} ."/$HOSTNAME";
	};

}; # sub scanner{ }
############ Subroutine zur Bearbeitung der Linktiefe, kann nicht als OO implementiert werden -> zu großer aufwand


############# Subroutine zum Einsammeln von Links für übergebene URL: Start
# Aufgabe: &sub_scanner_nothreads - erstelle neues Objekt und hole für übergebene url die links
# Rückgabe: @links mit links

sub sub_scanner {
	
	my $self			= shift; 
	my $ConfigHashRef	= shift;
	my $StatusHashRef	= shift;
	my $url_to_scan		= shift;

	my %SCANNER_CONFIG	= %{$ConfigHashRef};
	
	my $ProxyCFG = {
		"USEPROXY"	=> %SCANNER_CONFIG->{"USEPROXY"},
		"PROXYURL"	=> %SCANNER_CONFIG->{"PROXYURL"},
		"PROXYUSER"	=> %SCANNER_CONFIG->{"PROXYUSER"},
		"PROXYPASS"	=> %SCANNER_CONFIG->{"PROXYPASS"},
	};
	
	my $HOSTNAME		= %SCANNER_CONFIG->{"OBJECT"}->get_hostname( %SCANNER_CONFIG->{"URL"} );
	
	my $MIRROR_CFG_FILE, $STOREPATH_MIRROR, $STOREPATH, $content;
	my $SUB_SPIDER, $hostname, $html, @links, %metakeys, @title, $region1, $region2, $region3,$region4 , $region5, $region6, $region7, $region8, $region9,$region10;
	
	if ( lc( %SCANNER_CONFIG->{"OS"} ) eq "windows" ) {

		if ( $IS_BACKUPED eq  "0" ) {

			use File::Copy;
			my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
			my $year = $year + 1900;
			my $mon = $mon + 1;

			my $backup = %SCANNER_CONFIG->{"STOREPATH"} . "\\Backup-$HOSTNAME-[$mday.$mon.$year]-[$hour'$min'$sec]";
			my $org = %SCANNER_CONFIG->{"STOREPATH"} . "\\$HOSTNAME";
			move( $org , $backup);
			$IS_BACKUPED = "1";
		};

		mkdir( %SCANNER_CONFIG->{"STOREPATH"} . "\\$HOSTNAME", 0755);	
		mkdir( %SCANNER_CONFIG->{"STOREPATH"} . "\\$HOSTNAME\\MIRROR" , 0755);	
		mkdir( %SCANNER_CONFIG->{"STOREPATH"} . "\\$HOSTNAME\\" . uc( %SCANNER_CONFIG->{"OUTPUTFORMAT"} ) , 0755);
		$MIRROR_CFG_FILE	= %SCANNER_CONFIG->{"TMPPATH"} . "\\easymirror.cfg";
		$STOREPATH_MIRROR	= %SCANNER_CONFIG->{"STOREPATH"} . "\\$HOSTNAME\\MIRROR";
		$STOREPATH			= %SCANNER_CONFIG->{"STOREPATH"} . "\\$HOSTNAME\\" . uc(%SCANNER_CONFIG->{"OUTPUTFORMAT"});

	} else {

		if ( $IS_BACKUPED eq  "0" ) {

			use File::Copy;
			my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
			my $year = $year + 1900;
			my $mon = $mon + 1;

			my $backup = %SCANNER_CONFIG->{"STOREPATH"} . "/Backup-$HOSTNAME-[$mday.$mon.$year]-[$hour'$min'$sec]";
			my $org = %SCANNER_CONFIG->{"STOREPATH"} . "/$HOSTNAME";
			move( $org , $backup);
			$IS_BACKUPED = "1";
		};

		mkdir( %SCANNER_CONFIG->{"STOREPATH"} . "/$HOSTNAME", 0755);	
		mkdir( %SCANNER_CONFIG->{"STOREPATH"} . "/$HOSTNAME/MIRROR" , 0755);
		mkdir( %SCANNER_CONFIG->{"STOREPATH"} . "/$HOSTNAME/" . uc( %SCANNER_CONFIG->{"OUTPUTFORMAT"} ) , 0755);
		$MIRROR_CFG_FILE	= %SCANNER_CONFIG->{"TMPPATH"} . "/easymirror.cfg";
		$STOREPATH_MIRROR	= %SCANNER_CONFIG->{"STOREPATH"} . "/$HOSTNAME/MIRROR";
		$STOREPATH			= %SCANNER_CONFIG->{"STOREPATH"} . "/$HOSTNAME/" . uc(%SCANNER_CONFIG->{"OUTPUTFORMAT"});

	};
	
	if ( lc( %SCANNER_CONFIG->{"WORKTYPE"} ) eq "spider" ){
	
		if ( %SCANNER_CONFIG->{"STORE_FLAG"} eq "1") {	# wenn daten gespidert werden sollen, aber auch lokal gespeichert werden sollen
		
			# eval ist hier wichtig, weil es ohne zu ausnahmen kommen kann und das script beendet werden kann
			eval {
				my $MIRROR = Spider::Easymirror->new();
				$MIRROR->create_config_file( $url_to_scan , $MIRROR_CFG_FILE, $STOREPATH_MIRROR );
				$MIRROR->start_mirror( $MIRROR_CFG_FILE , 5);
				undef $MIRROR;
			};

		};

		# Hole das dukument ab -> wichtig hierbei die bestimmung des content types %{$HTMLHASHREF}->{'type'}
		$SUB_SPIDER		= Spider::Easyspider->new();
		$HTMLHASHREF	= $SUB_SPIDER->http_get( $url_to_scan , %SCANNER_CONFIG->{"TIMEOUT"}, %SCANNER_CONFIG->{"USERAGENT"}, $ProxyCFG );
				
		# wenn content type pdf oder filetype pdf dann werfe pdfparser an
		if ( %{$HTMLHASHREF}->{'type'} eq "application/pdf" || %{$StatusHashRef}->{"filetype"} eq "pdf" ) {
		
			$content = Spider::Parser->ParsePDF( $ConfigHashRef, $url_to_scan );

		} elsif ( %{$HTMLHASHREF}->{'type'} eq "application/msword" || %{$StatusHashRef}->{"filetype"} eq "doc" ) {

			$content = Spider::Parser->ParseDOC( $ConfigHashRef, $url_to_scan );

		} elsif ( %{$HTMLHASHREF}->{'type'} =~ /powerpoint/i || %{$StatusHashRef}->{"filetype"} eq "ppt" ) {

			$content = Spider::Parser->ParsePPT( $ConfigHashRef, $url_to_scan );

		} elsif ( %{$HTMLHASHREF}->{'type'} =~ /excel/i || %{$StatusHashRef}->{"filetype"} eq "xls" ) {

			$content = Spider::Parser->ParseXLS( $ConfigHashRef, $url_to_scan );		
	
		} elsif ( %{$HTMLHASHREF}->{'type'} =~ /rtf/i || %{$StatusHashRef}->{"filetype"} eq "rtf" ) {

			$content = Spider::Parser->ParseRTF( $ConfigHashRef, $url_to_scan );

		} elsif ( %{$HTMLHASHREF}->{'type'} eq "application/rss+xml" || %{$StatusHashRef}->{"filetype"} eq "rss" ) {
			
			$content = Spider::Parser->ParseRSS( %{$HTMLHASHREF}->{'content'} );
			
		} elsif ( %{$HTMLHASHREF}->{'type'} eq "text/xml" || %{$StatusHashRef}->{"filetype"} eq "xml" ) {
	
			$content = Spider::Parser->ParseXML( %{$HTMLHASHREF}->{'content'} );
			
		} else {

			@links		= $SUB_SPIDER->get_links( %{$HTMLHASHREF}->{'content'}, $url_to_scan);
			%metakeys	= $SUB_SPIDER->get_metakeys( %{$HTMLHASHREF}->{'content'} );
			@title 		= $SUB_SPIDER->get_title( %{$HTMLHASHREF}->{'content'} );
			$content 	= $SUB_SPIDER->get_body( %{$HTMLHASHREF}->{'content'} );
			$region1	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_1_TAG"}, $html );
			$region2	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_2_TAG"}, $html );
			$region3	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_3_TAG"}, $html );
			$region4	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_4_TAG"}, $html );
			$region5	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_5_TAG"}, $html );
			$region6	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_6_TAG"}, $html );
			$region7	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_7_TAG"}, $html );
			$region8	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_8_TAG"}, $html );
			$region9	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_9_TAG"}, $html );
			$region10	= $SUB_SPIDER->get_region_information( %SCANNER_CONFIG->{"REGION_10_TAG"}, $html );

			foreach $link (@links) {
				$link = "$CURRENTDEPTH " . $link;
			};
		};

		# use Unicode::UTF8simple;
		# my $uref = new Unicode::UTF8simple;
		# convert a string (here: schön) to a utf8 byte string 
		# my $content = $uref->toUTF8("iso-8859-1",$content);

		$LINKCOUNT++;
		$hostname	= &get_hostname("", $url_to_scan );
		
		my $OUTPUT = {
					
			"HOSTNAME"			=> $hostname,
			"URL"				=> $url_to_scan,
			"FILETYPE"			=> %{$StatusHashRef}->{"filetype"},
			"CONTENTTYPE"		=> %{$HTMLHASHREF}->{'type'},
			"SPIDER-DATE"		=> _getFullTime(),	
			"LINKCOUNT"			=> $LINKCOUNT,
			"LINKDEPTH"			=> $CURRENTDEPTH,
			"META-KEYS"			=> %metakeys->{uc('keywords')},
			"META-CONTENT"		=> %metakeys->{uc('content-type')},
			"META-PRAGMA"		=> %metakeys->{uc('pragma')},
			"META-REVISIT"		=> %metakeys->{uc('revisit-after')},
			"META-DESCRIPTION"	=> %metakeys->{uc('description')},
			"META-AUTHOR"		=> %metakeys->{uc('author')},
			"META-DATE"			=> %metakeys->{uc('date')},
			"META-PUBKLISHED"	=> %metakeys->{uc('published')},
			"META-CONTACT"		=> %metakeys->{uc('contact')},
			"TITLE"				=> @title,
			"REGION1"			=> $region1,
			"REGION2"			=> $region2,
			"REGION3"			=> $region3,
			"REGION4"			=> $region4,
			"REGION5"			=> $region5,
			"REGION6"			=> $region6,
			"REGION7"			=> $region7,
			"REGION8"			=> $region8,
			"REGION9"			=> $region9,
			"REGION10"			=> $region10,
			"REGION1TAG"		=> %SCANNER_CONFIG->{"REGION_1_TAG"},
			"REGION2TAG"		=> %SCANNER_CONFIG->{"REGION_2_TAG"},
			"REGION3TAG"		=> %SCANNER_CONFIG->{"REGION_3_TAG"},
			"REGION4TAG"		=> %SCANNER_CONFIG->{"REGION_4_TAG"},
			"REGION5TAG"		=> %SCANNER_CONFIG->{"REGION_5_TAG"},
			"REGION6TAG"		=> %SCANNER_CONFIG->{"REGION_6_TAG"},
			"REGION7TAG"		=> %SCANNER_CONFIG->{"REGION_7_TAG"},
			"REGION8TAG"		=> %SCANNER_CONFIG->{"REGION_8_TAG"},
			"REGION9TAG"		=> %SCANNER_CONFIG->{"REGION_9_TAG"},
			"REGION10TAG"		=> %SCANNER_CONFIG->{"REGION_10_TAG"},

		}; 
		
		# speichere dei results als XML
		my $obj_ResultParser = Spider::ResultParser->FormatXMLComplex( $STOREPATH, %SCANNER_CONFIG->{"OS"},  $OUTPUT, $HOSTNAME, $content );
	
	} elsif ( lc( %SCANNER_CONFIG->{"WORKTYPE"} ) eq "mirror" ) {	#if ( $WORKTYPE eq "spider"){
		
		my $SUB_MIRROR	= Spider::Easyspider->new();
		my $mirrorhtml	= $SUB_MIRROR->http_get( $url_to_scan, %SCANNER_CONFIG->{"TIMEOUT"}, %SCANNER_CONFIG->{"USERAGENT"}, $ProxyCFG );
		my @links		= $SUB_MIRROR->get_links( %{$mirrorhtml}->{'content'}, $url_to_scan );
	
		foreach $link (@links) {
			$link = "$CURRENTDEPTH " . $link;
		};
		
		eval {	
			my $MIRROR = Spider::Easymirror->new();
			$MIRROR->create_config_file( $url_to_scan , $MIRROR_CFG_FILE, $STOREPATH_MIRROR );
			$MIRROR->start_mirror( $MIRROR_CFG_FILE , 5 );
			undef $MIRROR;
		};
		
		undef $MIRROR, $SUB_MIRROR, $mirrorhtml, $LINK_ARRAYREF;
		
		return \@links;
		
	};
	
}; # sub sub_scanner {}
############# Subroutine zum Einsammeln von Links für übergebene URL: Start


1;

=pod

=head1 NAME

EasySpiderTCPClient, EasySpiderTCPServer

=head1 SYNOPSIS

system("perl EasySpiderTCPServer.pl --config=easyspider.server.cfg");

=head1 DESCRIPTION

Nowadays working with Deep Learning, Machine Learning or even Artificial Intelligence you need a lot of Training Data. This crawling framework was developed by me in 2005 and 2006 in Perl5. I am releasing it so that Perl beginners can take a look at code. I am using deep learning to realize mostly language related tools in the field of Natural Language Generation like Text Generation. My most advanced Text Generator is ArtikelSchreiber.com. 

=over
=item * Crawling and mirroring of Webpages
=item * Extracting of HTML Tags and Content between Tags
=item * Client/Server Modus
=item * Configuration file support
=item * Extracting of HTML, PDF, DOC/DOCX
=item * Convertion to XML File Format
=back

=back
=head1 LICENSE
Copyright 2005, 2006 

This is released under the Artistic 
License.


=head1 AUTHOR
Sebastian Enger, M.Sc., B.Sc.

L<Dein automatischer ArtikelSchreiber|http://www.artikelschreiber.com/>	-	
L<Deutscher ArtikelSchreiber Blog|http://www.artikelschreiber.com/de/blog/>	-	
L<Text Generator: Article Writer|http://www.artikelschreiber.com/en/>	-	
L<English ArtikelSchreiber Blog|http://www.artikelschreiber.com/en/blog/>	-	
L<ArtikelSchreiber Marketing Tools|http://www.artikelschreiber.com/marketing/>	-	
L<Text Generator deutsch - KI Text Generator|http://www.unaique.net/>	-	
L<KI Blog|http://www.unaique.net/blog/>	-	
L<CopyWriting: Generator for Marketing Content by AI|http://www.unaique.net/en/>	-	
L<Recht Haben - Muster und Anleitung fuer Verbraucher|http://rechthaben.net/>	-	
L<AI powered intelligent language transformation|http://www.unaique.com/>

=cut