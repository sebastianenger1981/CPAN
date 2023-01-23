#!/usr/bin/perl

package Spider::Easymirror;
$VERSION = '1.0';

use Tie::File;


########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class) = @_;
	my $object = bless {}, $class;
	return $object;

};  #sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende

################## Subroutinen zum Erstellen der Configuration: Start
# Aufgabe: &create_config_file - erstelle config in speicher und speichere es
# Rückgabe: easymirror.cfg mit gespeicherten konfigurationsoptionen
# TODO: den eigenen hostname bestimmen und unter interface dann speichern

sub create_config_file(){
	my ($self, $url, $cfg_file, $storepath) = @_;

	tie @configuration, 'Tie::File', $cfg_file or die "&create_config_file(): Cannot create File: $!\n";
	undef @configuration;
	
	my @config = (	
			"agent Easy-spider/1.95 - Mirroring Bot - bigfish82@gmail.com",
			"allframes",
			"allpictures",
		#	"#auth http://www.mydom.com/* * peter:tarkabarka",
			"believe Content-length",
			"directory $storepath",
		#	"cookie no",
		#	"cookie domain",
		#	"cookie save session",
		#	"cookie file file_name.txt",
			"exclude *.rm",
			"exclude *.ram",
			"leafs",
			"level 20000",
			"log mirror.log",
			"map simple",
			"pagesizelimit 10M",
		#	"#proxy http://proxy.cnn.com:80 *.cnn.com/*",
			"pictures",
			"size 3000M",
			"interface osiris",
		#	"interface linus2.nx.htwm.de",
			"start $url"
		);

	push(@configuration, @config);
	untie @configuration;
	
	return 1;
} # sub create_config_array(){
################## Subroutinen zum Erstellen der Configuration: Ende


################## Subroutinen zum Mirrorn: Start
# Aufgabe: &start_mirror - starte den mirror vorgang
# Rückgabe: nix

sub start_mirror(){
	
	my ($self, $config_file, $depth) = @_;
	
&process_command_file($config_file);

$version          = '2.45 pre-release';

@include          = (); # domains to include
@exclude          = (); # domains to exclude
$maximal_deepness = $depth;  # how long should we follow links
$maximal_size     = 1024*1024*10; # max 1 MB
$pictures         = 1;  # download pictures
$allpictures      = 0;  # get all pictures even those which are out of the included domain
$allframes        = 0;  # include html pages that are part of a frame even if they are out of the included domain
$picpriority      = 0;  # treat pictures as ordinary page (do not rush for them)
$create_leafs     = 1;  # create redirect files for pages that are too deep
$regexps_are_perl = 0;  # patterns are normal, * is wild car and that is all
$use_full_url     = 1;  # use full URL on GET even without proxy

$current_size = 0; #downloaded bytes so far

while( $page = webpage->next_page ){
  last if $maximal_size && $current_size >= $maximal_size;
  next if $page->fetch_state eq 'SAVED';

  my $page_level = $page->level;
  if( $maximal_deepness && $page_level > $maximal_deepness ){
    $url = $page->url;
    $page->{'HEADER'}->{'content-type'} = 'text/html';
    $page->file;
    $page->text_leaf;
    $page->create_file if $create_leafs;
    $page->destroy;
    next;
    }

redirected:
  $page->calculate_auth;

authretry:

  $page->get;

  my $status = $page->{'STATE'};

  if( $status == 502 || # Service temporarily overloaded
      $status == 503 || # Gateway timeout
      $status == 603    # Timed out
    ){
    $page->fetch_state('FRESH');
    $page->schedule;
    next;
    }

  if( $status == 401 &&               # failed password
      $page->auth_type eq 'basic' &&  # authentication is basic (we can not do anything else recently)
      defined($page->{'AUTHLIST'}) && # we have username:password list defined
      $#{$page->{'AUTHLIST'}} >= 0 ){ # and have at least one members left to try
    $page->fetch_state('SCHEDULED');  # 'sub get' is lasy and said it was already retrieved,
                                      # but it is not the way like 'sub get' thinks. 'sub get' should try again!
    goto authretry;                   # try again with the next username:password
    # do you know that all listed usernames and password will be tried for
    # each page retrieved in the domain? It does not learn from previous
    # retrievals. It tries and tries all passwords, so do not be crasy and define only
    # one auth for a domain!
    }

  if( ( $status >= 400 && $status <= 404 ) ||
        $status == 501 ||
      ( $status >= 600 && $status <= 602 ) ){
    $page->text_badstate;
    $page->create_file if $create_leafs;
    $page->destroy;
    next;
    }

  if( $status == 301 || $status == 302 ){
    my $URL = $page->{'HEADER'}->{'location'};
    my $file;
    my $redir;
    my $follow_redirect;
    if( $follow_redirect = &can_get( $URL ) ){
      $redir = webpage($URL);
      webpage->log("REDIRECT to $URL");
      $redir->schedule;
      $file = $page->relate($redir);
      }else{ $file = $URL; }# this is an absolute URL
    $page->text_redirect( $file );
    $page->create_file;
    $page->destroy;
    next unless $follow_redirect;
    $page = $redir;
    goto redirected;
    }

  if( $status >= 200 && $status < 300 ){
    $current_size += $page->length;
    if( $maximal_size && $current_size > $maximal_size ){
      webpage->log('QUOTA retrieving '.$page->url.' process exceeded.');
      webpage->log('QUITting download loop.');
      last; # quit from download loop
      }
    if( $page->content_type eq 'text/html' ){
      $page->split_html;
      delete $page->{'CONTENT'}; # we delete and the rebuild the content
      for $tag ( @{$page->{'SPLIT'}} ){
        next if $tag->{'TYPE'} eq 'TEXT';
        my $tagtype = $tag->{'CONTENT'}->[0];
        my $tags = $tag->{'CONTENT'}->[1];

        #   <A HREF="....." >

        if( ('a' eq $tagtype || 'area' eq $tagtype) && defined($tags->{'href'}) ){
          my $href = $page->urel2abs($tags->{'href'});
          my $hrefa = $href; # url with optional anchor
          $href =~ s/\#([^\/]*)$//; # delete anchor
          my $anchor = $1;
          if( &must_get( $href ) ){
            my $tpage = webpage($href);
            $tpage->level($page_level + 1);
            $tpage->schedule;
            $tags->{'href'} = $page->relate($tpage); # point to the copied url
            $tags->{'href'} .= '#' . $anchor if $anchor;
            }else{
            $tags->{'href'} = $hrefa; # point absolute to the external, not copied url
            }
          }

        # <META HTTP-EQUIV="Refresh" CONTENT="1; URL=http://....">

        elsif( 'meta' eq $tagtype && lc($tags->{'http-equiv'}) eq 'refresh' ){
          next unless $tags->{'content'} =~ /(\d+)\;\s*url\=(.*)/i;
          my $delay = $1;
          my $href = $page->urel2abs($2);
          my $hrefa = $href; # href with optional anchor
          $href =~ s/\#[^\/]*$//; # delete anchor
          if( &must_get( $href ) ){
            my $tpage = webpage($hrefa);
            $tpage->level($page_level + 1);
            $tpage->schedule;
            $tags->{'content'} = "$delay; URL=" . $page->relate($tpage); # point to the copied url
            }else{
            $tags->{'content'} = "$delay; URL=$href"; # point absolute to the external, not copied url
            }
          }

        #   <IMG SRC="....." >

        elsif( 'img' eq $tagtype && $pictures && defined($tags->{'src'}) ){
          my $href = $page->urel2abs($tags->{'src'});
          my $hrefa = $href; # href with optional anchor
          $href =~ s/\#[^\/]*$//; # delete anchor
          if( ( $allpictures && &can_get($href) ) || &must_get( $href ) ){
            my $tpage = webpage($hrefa);
            $tpage->level($page_level);
            $tpage->schedule;
            $tags->{'src'} = $page->relate($tpage);
            }
          }

        #   <FRAME SRC="....." >
        elsif( ('frame' eq $tagtype || 'iframe' eq $tagtype) && defined($tags->{'src'}) ){
          my $href = $page->urel2abs($tags->{'src'});
          my $hrefa = $href; # href with optional anchor
          $href =~ s/\#([^\/]*)$//; # delete anchor
          my $anchor = $1;
          if( ( $allframes && &can_get($href) ) || &must_get( $href ) ){
            my $tpage = webpage($hrefa);
            $tpage->level($page_level);
            $tpage->schedule;
            $tags->{'src'} = $page->relate($tpage);
            $tags->{'src'} .= '#' . $anchor if $anchor;
            }
          }

        #   <FORM ACTION="....." >
        # we do not follow form actions, but the url should be converted to absolute
        elsif( 'form' eq $tagtype && defined($tags->{'action'}) ){
          my $href = $page->urel2abs($tags->{'action'});
          $tags->{'action'} = $href; # point absolute to the external, not copied url
          }

        }
      $page->rebuild_content;
      }
    $page->create_file;
    $url_state{$page->url} = 'DONE';
    }
  }

#exit;


sub can_get {
  my $url = shift;

  return 1 unless $url =~ m{^\w+:}; # relative url is fine
  return 1 if $url =~ m{http://}; # http is fine
  return 0;
  }


sub must_get {
  my $url = shift;

  return 0 unless &can_get($url);

  $url = webpage->normalize_url($url);

  my $pattern;
  my $y=0;
  for $pattern ( @include ){
    if( $url =~ /$pattern/ ){
      $y = 1;
      last;
      }
    }

  return 0 unless $y;

  for $pattern ( @exclude ){
    return 0 if $url =~ /$pattern/;
    }
  return 1;
  }


sub print_help {
  print <<END__HELP;
WEBMIRROR PRO $version
Usage: 
       webmirror [-s] -f retrieval_definition_file
or
       webmirror [-s] -f STDIN

to read the retrieval definition from the standard input.

Use -s to supress STDOUT logging.

For further information see the product documentation at
                http://www.isys.hu/c/verhas6progs/perl/webmirror
END__HELP
  }

sub process_command_file {
  my $command_file = shift;
  my $lines;

  if( $command_file eq 'STDIN' ){
    my $oldsep = $/; undef $/;
    $lines = <STDIN>;
    $/ = $oldsep;
    close STDIN; # no reason to keep it open
    }else{
    open(F,"<$command_file") or die "Can not open command file $command_file";
    my $oldsep = $/; undef $/;
    $lines = <F>;
    $/ = $oldsep;
    close F;
    }
  while( $lines =~ /^(config\s+.*)$/m ){
    my $includef = $1;
    $include = quotemeta $includef;
    $includef =~ s/^config\s*//;
    open(F,"<$includef") or die "Can not open command file $includef";
    my $oldsep = $/; undef $/;
    my $inclines = <F>;
    $/ = $oldsep;
    close F;
    $lines =~ s/$include/$inclines/mg;
    }
  my @lines = split(/\n+/ , $lines);
  $lines = '';
  for( @lines ){
    my $command;
    my $parameter;

    chomp;
    s/^\s*//;s/\s*$//; # delete leading and trailing spaces
    next if /^\s*$/;# ignore empty lines
    next if /^\s*\#/; #ignore comment lines

    if( /(\w+)\s+(.*)/ ){
      $command = $1;
      $parameter = $2;
      }
    elsif( /(\w+)/ ){
      $command = $1;
      $parameter = '';
      }
    else{
      print STDERR "line '$_' ignored. Syntax error.\n";
      next;
      }

    if( $command eq 'log' ){
      $webpage::log_file = $parameter;
      next;
      }

    if( $command eq 'map' ){
      $webpage::map_method = $parameter;
      next;
      }

    if( $command eq 'start' ){
      $parameter = 'http://' . $parameter unless $parameter =~ m{^http://};
      my $page = new webpage( $parameter );
      $page->schedule;
      $page->level(1);
      next;
      }

    if( $command eq 'include' ){
      $parameter = 'http://' . $parameter unless $parameter =~ m{^http://};
      $parameter = &regexp_it($parameter);
      push @include , $parameter;
      next;
      }

    if( $command eq 'regexp' ){
      if( $parameter eq 'perl' ){
        $regexps_are_perl = 1;
        next;
        }elsif( $parameter eq 'normal' ){
        $regexps_are_perl = 0;
        next;
        }
      }

    if( $command eq 'exclude' ){
      $parameter = 'http://' . $parameter unless $parameter =~ m{^http://};
      $parameter = &regexp_it($parameter);
      push @exclude , $parameter;
      next;
      }

    if( $command eq 'level' ){
      if( $parameter eq 'inf' ){
        $maximal_deepness = 0;
        }else{
        $maximal_deepness = $parameter;
        }
      next;
      }

    if( $command eq 'directget' ){
      if( $parameter eq 'partial' ){
        $use_full_url = 0;
        }
      if( $parameter eq 'full' ){
        $use_full_url = 1;
        }
      next;
      }

    if( $command eq 'size' ){
      if( $parameter eq 'inf' ){
        $maximal_size = 0;
        next;
        }
      $maximal_size = &prep_postf($parameter);
      next;
      }

    if( $command eq 'directory' ){
      webpage->cwd($parameter);
      next;
      }

    if( $command eq 'allpictures' ){
      $allpictures = 1;
      next;
      }

    if( $command eq 'allframes' ){
      $allframes = 1;
      next;
      }

    # try this first without authentication
    # noauth http://*.mydomain.com
    if( $command eq 'noauth' ){
      $parameter = &regexp_it($parameter);
      push @webpage::noauth_domain , { 'DOMAIN' => $domain ,
                                       'REALM'  => '.*' ,
                                       'AUTHS'  => '' , # this means w/o authentication
                                      };
      next;
      }

    # auth http://www.mydomain.com/* realm username:password
    if( $command eq 'auth' ){
      $parameter =~ /(\S+)\s*(.*)$/;
      my $domain = &regexp_it($1);
      $parameter = $2;
      $parameter =~ /(\S+)\s*(.*)$/;
      my $realm  = &regexp_it($1);
      $parameter = webpage->base64($2);
      push @webpage::auth_domain , { 'DOMAIN' => $domain ,
                                     'REALM'  => $realm ,
                                     'AUTH'  => $parameter ,
                                    };
      next;
      }

    if( $command eq 'pictures' ){
      $pictures = 1;
      if( $parameter eq 'first' ){
        $picpriority = 1; # schedule img url to the start of the schedule list
        }else{
        $picpriority = 0; # schedule img url to the end of the schedule list
        }                 # just like html pages
      next;
      }

    if( $command eq 'nopictures' ){
      $pictures = 0;
      $picpriority = 0; # useless but set it to default
      next;
      }

    if( $command eq 'leafs' ){
      $create_leafs = 1;
      next;
      }

    if( $command eq 'noleafs' ){
      $create_leafs = 0;
      next;
      }

    if( $command eq 'proxy' ){
      if( $parameter =~ /(.+)\s+(.+)/ ){
        my $proxy = $1;
        my $domain = $2;
        $domain = &regexp_it($domain);
        webpage->define_proxy( $proxy , $domain );
        }else{
        webpage->define_proxy( $proxy );
        }
      next;
      }

    if( $command eq 'interface' ){
      if( $parameter =~ /(.+)\s+(.+)/ ){
        my $if = $1;
        my $pattern =  &regexp_it($2);
        webpage->define_interface( $if , $pattern );
        }else{
        webpage->define_interface( $parameter , '.*' );
        }
      next;
      }

    if( $command eq 'pagesizelimit' ){
      if( $parameter eq 'inf' ){
        $webpage::pagesizelimit = 0;
        next;
        }
      $webpage::pagesizelimit = &prep_postf($parameter);
      next;
      }

    if( $command eq 'unbelieve' ){
      if( lc($parameter) eq 'content-length' ){
        $webpage::cl_believe = 0;
        next;
        }
      }
    if( $command eq 'believe' ){
      if( lc($parameter) eq 'content-length' ){
        $webpage::cl_believe = 1;
        next;
        }
      }

    if( $command eq 'agent' ){
      $webpage::USERAGENT = $parameter;
      next;
      }

    if( $command eq 'cookie' || $command eq 'cookies' ){
      if( $parameter eq 'no' ){
        $webpage::do_cookies = 0;
        next;
        }
      if( $parameter eq 'yes' ){
        $webpage::do_cookies = 1;
        next;
        }
      if( $parameter eq '3dots' ){
        $webpage::count_cookie_dots = 2;
        next;
        }
      if( $parameter eq 'dots' ){
        $webpage::count_cookie_dots = 1;
        next;
        }
      if( $parameter eq 'nodots' ){
        $webpage::count_cookie_dots = 0;
        next;
        }
      if( $parameter eq 'domain' ){
        $webpage::care_cookie_domain = 1;
        next;
        }
      if( $parameter eq 'nodomain' ){
        $webpage::care_cookie_domain = 0;
        next;
        }
      if( $parameter =~ /save\s+session/ ){
        $webpage::save_session_cookies = 1;
        next;
        }
      if( $parameter =~ /don\'?t\s+save\s+session/ ){
        $webpage::save_session_cookies = 0;
        next;
        }
      if( $parameter =~ /backup\s+(\d+)/ ){
        $webpage::cookie_file_backup_nr = $1;
        next;
        }
      if( $parameter =~ /file\s+(.*)/ ){
        $webpage::cookie_file = $1;
        webpage->load_cookies($webpage::cookie_file);
        next;
        }
      if( $parameter =~ /load\s+(.*)/ ){
        webpage->load_cookies($1);
        next;
        }
      }

    print STDERR "line '$_' ignored\n";
    }
  }


sub prep_postf {
  my $p = shift;

  if( $p =~ s/M$// ){ $p *= 1024*1024 }
  elsif( $p =~ s/K$// ){ $p *= 1024 }
  return $p;
  }


sub regexp_it {
  my $string = shift;

  return $string if $regexps_are_perl;

  $string = quotemeta $string;
  $string =~ s/\\\*/.*/g; #make * the joker character
  return $string;
  }


package webpage;

BEGIN {
  $umask = 0777;
  $USERAGENT = 'Easy-Spider.de/1.0';

  $map_method = 'simple'; # by default we do not create sub directories like com/digital/www/80/...
  $map_counter = 1; # file name counter when mapping is 'flat'
  $object_hash = {}; # containing all objects created
  @schedule_list = ();

  %host_ip = (); # store the ip addresses for hosts already accessed
  %ip_host = (); # and store the reverse

  @proxies          = (); # proxies to use
  $save_directory   = '.';# where to store the result
  $log_file         = ''; # where to write the log
  $log_opened       = 'NOT YET';
  $log_stderr_on    = 0;  # we do not send log messages to stderr by default
  $log_stdout_on    = 1;  # we        send log messages to stdout by default

  $pagesizelimit    = 0;  # no page size limit by default
  $cl_believe       = 1;  # do believe reported content length
  @auth_domain      = (); # list of domains that authentication was defined
  @noauth_domain    = (); # list of domains that should be first tried w/o authentication

  $interfaces_defined = 0;
  my $hostname = `hostname`;
  chomp $hostname;
  @interfaces = ($hostname);
  %interfaces = ( $hostname => '.*' );

  @mdays   = ( '31', '28', '31', '30', '31', '30', '31', '31', '30', '31', '30', '31' );

  $do_cookies = 1; # process cookies

  @cookies = (); # each item is a pointer to a hash of { NAME => ?? , VALUE => ??,
                 #                                       EXPIRES => ??, PATH => ?? ,
                 #                                       DOMAIN => ??, SECURE => 0|1 }

  $count_cookie_dots = 1; # 0 = do not care how many dots there are
                          # 1 = request at least two dots (default)
                          # 2 = request two or three dots (according to the spec, but it is crasy! *.mydom.hu ??)

  $care_cookie_domain = 1;# check that the indicated domain fits the sender (i.e. www.cnn.com should not
                          # send a cookie with the domain .bbc.com)

  $save_session_cookies = 0; # do not save the cookies that have no expiration time

  $cookie_file_backup_nr = 100; # how many backup files to keep from old cookie files with names:
                                # cookie.txt.00 ,cookie.txt.01 ,cookie.txt.02 ,cookie.txt.03 ...


  $cookie_file = ''; # where to save the cookies

  %mime_extension = (
'application/x-gzip' => ['gz'],
'application/x-compress' => ['Z'],
'applicarion/x-ns-proxy-autoconfig' => ['pac'],
'application/x-javascript' => ['js','ls','mocha'],
'application/x-tcl' => ['tcl'],
'application/x-sh' => ['sh'],
'application/x-csh' => ['csh'],
'application/postscript' => ['ai','eps','ps'],
'application/octet-stream' => ['exe','~.*'], # match all extensions
'application/x-cpio' => ['cpio'],
'application/x-gtar' => ['gtar'],
'application/x-tar' => ['tar'],
'application/x-shar' => ['shar'],
'application/x-zip-compressed' => ['zip'],
'application/x-stuffit' => ['sit'],
'application/mac-binhex40' => ['hqx'],
'video/x-msvideo' => ['avi'],
'video/quicktime' => ['qt','mov'],
'video/mpeg' => ['mpeg','mpg','mpe'],
'audio/x-wav' => ['wav'],
'audio/x-aiff' => ['aif','aiff','aifc'],
'audio/basic' => ['au','snd'],
'application/fractals' => ['fif'],
'image/ief' => ['ief'],
'image/x-MS-bmp' => ['bmp'],
'image/x-rgb' => ['rgb'],
'image/x-portable-pixmap' => ['ppm'],
'image/x-portable-graymap' => ['pgm'],
'image/x-portable-bitmap' => ['pbm'],
'image/x-portable-anymap' => ['pnm'],
'image/x-xwindowdump' => ['xwd'],
'image/x-xpixmap' => ['xpm'],
'image/x-xbitmap' => ['xbm'],
'image/x-cmu-raster' => ['ras'],
'image/tiff' => ['tiff','tif'],
'image/jpeg' => ['jpeg','jpg','jpe'],
'image/gif' => ['gif'],
'application/x-fexinfo' => ['texi'],
'application/x-fexinfo' => ['texinfo'],
'application/x-dvi' => ['dvi'],
'application/x-latex' => ['latex'],
'application/x-tex' => ['tex'],
'application/rtf' => ['rtf'],
'text/html' => ['html','htm'],
'text/plain' => ['txt','text'],
   );

  }

END {
  if( $cookie_file ){
    webpage->save_cookies($cookie_file);
    }
  }


sub calculate_auth {
  my $self = shift;

  return if defined $self->{'AUTHLIST'};

  for( @noauth_domain ){
    if( $self->url =~ /$_->{'DOMAIN'}/ ){
      $self->{'AUTHLIST'} = [ { 'REALM' => '.*' , 'AUTH' => '' } ];
      last;# if one mathces it is enough. we won't try several times w/o password only once
      }
    }

  $self->{'AUTHLIST'} = [] unless defined $self->{'AUTHLIST'};


  for( @auth_domain ){
    if( $self->url =~ /$_->{'DOMAIN'}/ ){
      push @{$self->{'AUTHLIST'}} , { 'REALM' => $_->{'REALM'} , 'AUTH' => $_->{'AUTH'} };
      }
    }
  }


sub new {
  my $class = shift;
  my $url = shift;

  $url =~ s/\#[^\/]*$//; # delete anchor if it exists (page never has an anchor)

  if( $object_hash{$url} ){# return the object if it was already created
    return $object_hash{$url};
    }
  my $self = {};
  bless $self,$class;
  $url = 'http://' . $url unless $url =~ m{^http://};
  $self->{'URL'} = $url;
  $self->fetch_state('FRESH');
  $object_hash{$url} = $self;
  return $self;
  }


sub log {
  shift;
  my $text = shift;
  my $now = time();
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($now);
  $year +=1900;
  $mon++;
  $mon  = '0' . $mon  if $mon  < 10;
  $mday = '0' . $mday if $mday < 10;
  $sec  = '0' . $sec  if $sec  < 10;
  $hour = '0' . $hour if $hour < 10;
  $min  = '0' . $min  if $min  < 10;

  $text = "$year.$mon.$mday $hour:$min:$sec $text";
  print STDERR "$text\n" if $log_stderr_on;
  print STDOUT "$text\n" if $log_stdout_on;
  return unless $log_file;
  return if $log_opened eq 'FAILED';
  my $fom = '>';

  $fom .= '>' unless $log_opened eq 'NOT YET';

  if( ! open(LOG,"$fom$log_file") ){
    $log_opened = 'FAILED';
    print STDERR "Log file $log_file can not be opened.\n";
    return;
    }else{ $log_opened = 'YES' }

  print LOG "$text\n";
  close LOG;
  
  return;
  }


sub define_proxy {
  shift; # class method
  my $proxy = shift;
  my $domain = shift;

  $domain = '.*' unless defined $domain;

  push @proxies , { 'PROXY' => $proxy , 'DOMAIN' => $domain };
  }


sub save_cookies {
  shift; #class
  my $file = shift;

  # create backup files
  if( $cookie_file_backup_nr && -e $file ){
    my $i;
    for $i ( 0 ... $cookie_file_backup_nr-1 ){
      $i = ('0' x (length($cookie_file_backup_nr-1)-length($i)) ) . $i;
      if( ! -e "$file.$i" ){
        if( rename $file , "$file.$i" ){
          $i++;
          $i = 0 if $i == $cookie_file_backup_nr;
          $i = ('0' x (length($cookie_file_backup_nr-1)-length($i)) ) . $i;
          unlink "$file.$i";
          last;
          }
        }
      }
    }

  my $timeNow = time(); # expired cookies are not saved

  if( ! open($file,">$file") ){
    webpage->log("ERROR The cookie file $file was not saved.");
    return;
    }
  for $this_cookie ( @cookies ){
    if(  ( $save_session_cookies && $this_cookie->{'EXPIRES_CONVERTED'} == -1 ) || 
         $this_cookie->{'EXPIRES_CONVERTED'} > $timeNow ){ # not expired yet
      print $file $this_cookie->{'NAME'},'=',$this_cookie->{'VALUE'};
      if( $this_cookie->{'EXPIRES_CONVERTED'} != -1 ){
        print $file '; expires=',$this_cookie->{'EXPIRES'};
        }
      print $file '; path=',$this_cookie->{'PATH'};
      print $file '; domain=',$this_cookie->{'DOMAIN'};
      print $file '; secure' if $this_cookie->{'SECURE'};
      print $file "\n";
      }
    }
  close $file;
  }


sub load_cookies {
  shift; #class
  my $file = shift;

  if( ! open($file,"<$file") ){
    webpage->log("ERROR the cookie file $file was not loaded.");
    return;
    }
  my $my_care_cookie_domain = $care_cookie_domain;
  my $my_count_cookie_dots = $count_cookie_dots;

  my $dummy = webpage->new('http://www.isys.hu/c/verhas'); # it is a dummy, it could be any url

  while( <$file> ){
    chomp;
    $dummy->set_cookie($_);
    }
  close $file;
  my $care_cookie_domain = $my_care_cookie_domain;
  my $count_cookie_dots = $my_count_cookie_dots;
  }


sub list_cookies {
  my $self = shift;

  my $i,$j; # index variables for sorting cookies

  my $domain = $self->host;
  my $path   = $self->path;
  my $timeNow = time(); # expired cookies are not listed

  my $this_cookie;
  my @cookie_list = ();
  for $this_cookie ( @cookies ){
    my $domainpattern = '.*' . quotemeta($this_cookie->{'DOMAIN'}) . '$';
    my $pathpattern   = quotemeta($this_cookie->{'PATH'}) . '.*$'; 
    if(  $domain =~ /$domainpattern/ && $path =~ /$pathpattern/ && # domain and path is OK
         ($this_cookie->{'EXPIRES_CONVERTED'} == -1 || # there is no expiration defined
         $this_cookie->{'EXPIRES_CONVERTED'} > $timeNow ) ){ # or not expired yet
      push @cookie_list , $this_cookie;
      }
    }

  # simple buble sort to order the cookies so that the more
  # precise path comes first as it is required by the spec.
  for $i ( 0 .. $#cookie_list-1 ){
    for $j ( $i+1 .. $#cookie_list ){
      if( length($cookie_list[$i]->{'PATH'}) < length($cookie_list[$j]->{'PATH'}) ){
        my $swap = $cookie_list[$i];
        $cookie_list[$i] = $cookie_list[$j];
        $cookie_list[$j] = $swap;
        }
      }
    }

  my $list = '';
  for( @cookie_list ){
    $list .= '; ' if $list;
    $list .= $_->{'NAME'} . '=' . $_->{'VALUE'};
    }
  return $list;
  }


sub set_all_cookies {
  my $self = shift;

  if( defined $self->{'HEADER'}->{'set-cookie'} ){
    $self->set_cookie($self->{'HEADER'}->{'set-cookie'});
    }

  if( defined($self->{'HEADERc'}->{'set-cookie'}) &&
      $#{$self->{'HEADERc'}->{'set-cookie'}} > -1 ){
    my $thisccokie;
    for $thiscookie ( @{$self->{'HEADERc'}->{'set-cookie'}} ){
      $self->set_cookie($thiscookie);
      }
    }

  }


sub set_cookie {
  my $self = shift;
  my $cookie_string = shift; # NAME=VALUE; expires=DATE;path=PATH; domain=DOMAIN_NAME; secure

  my ($expires,$path,$domain,$secure);
  my $i; # loop index variable going through the cookie array

  $cookie_string =~ s/\s*(.*?)\s*;//;
  my $name_value = $1;
  my ($name,$value) = split(/=/ , $name_value);
  my @params = split(/;/,$cookie_string);
  for( @params ){
    s/^\s*//; s/\s*$//;
    if( /^secure$/i ){
      $secure = 1;
      next;
      }
    if( /expires\s*=\s*(.*)/i ){
      $expires = $1;
      next;
      }
    if( /path\s*=\s*(.*)/i ){
      $path = $1;
      next;
      }
    if( /domain\s*=\s*(.*)/i ){
      $domain = $1;
      next;
      }
    }

  $path    = $self->path unless defined $path;    # path that the cookie comes from
  $secure  = 0           unless defined $secure;  # it is not secure by default
  if( defined $expires ){
    $expires_converted = webpage->cookieT2time($expires);
    }else{  $expires_converted =-1 } # expires by the end of session


  if( defined( $domain ) ){
    if( $care_cookie_domain ){
      my $domainpattern = '.*' . quotemeta($domain) . '$' ;
      if( $self->host !~ /$domainpattern/ ){
        webpage->log("ERROR cookie domain $domain has not fit sending url ", $self->url);
        return;
        }
      }
    }else{
    # default is the machine that sends the cookie and it obviously fits itself
    $domain  = $self->host;
    }

  if( $count_cookie_dots ){
    # calculate the number of dots in the domain parameter
    # the spec requires at least two or three
    my $dot_nr = length( $domain =~ /\./g );
    if( $count_cookie_dots == 2 ||
        $domain =~ /\.gov/i || 
        $domain =~ /\.edu/i || 
        $domain =~ /\.net/i || 
        $domain =~ /\.org/i || 
        $domain =~ /\.com/i || 
        $domain =~ /\.mil/i || 
        $domain =~ /\.int/i   ){
       $dot_nr -= 2;
       }else{ $dot_nr -= 3 }
    if( $dot_nr < 0 ){
      webpage->log("ERROR cookie domain $domain has not enough dots in it.");
      return;
      }
    }

  for $i ( 0 .. $#cookies ){

    if( $cookies[$i]->{'NAME'} eq $name && 
        $cookies[$i]->{'DOMAIN'} eq $domain && 
        $cookies[$i]->{'PATH'} eq $path ){
      $cookies[$i]->{'VALUE'} = $value;
      $cookies[$i]->{'EXPIRES'} = $expires;
      $cookies[$i]->{'EXPIRES_CONVERTED'} = $expires_converted;
      $cookies[$i]->{'SECURE'} = $secure;  # later version may support HTTPS
      return; # the old cookie is stored with the new value
      }
    }

  push @cookies , {
    'DOMAIN' => $domain,
    'PATH' => $path,
    'NAME' => $name,
    'VALUE' => $value,
    'EXPIRES' => $expires,
    'EXPIRES_CONVERTED' => $expires_converted ,
    'SECURE' => $secure # later version may support HTTPS
    };
  return; # the cookie was stored as a new value
  }


sub cookieT2time {
  shift; #class
  my $cookie_time = shift; # of the format Wdy, DD-Mon-YY HH:MM:SS GMT

  # convert the string into separate values
  $cookie_time =~ /.*\,\s*(\d+)\-(\w+)\-(\d+)\s*(\d+):(\d+):(\d+)/i;
  my ($mday,$moname,$year,$hour,$min,$sec) = ($1,$2,$3,$4,$5,$6);

  # the stupid cookie time format is not Y2K
  # we do our best works from 1998 till 2098 and when year is given as YYYY
  if( length($year) == 2 ){
    if( $year eq '98' || $year eq '99' ){
       $year += 1900;
       }else{
       $year += 2000;
       }
    }# now we have a four digit year

  # get the serial number of the month
  $month = { 'jan' =>  0 , 'feb' =>  1 , 'mar' =>  2 , 'apr' =>  3 ,
             'may' =>  4 , 'jun' =>  5 , 'jul' =>  6 , 'aug' =>  7 ,
             'sep' =>  8 , 'oct' =>  9 , 'nov' => 10 , 'dec' => 11
           } -> { lc $moname };

  # count the days since the epoch (January 1, 1970.)
  my $ds = 0;
  for(1970 .. $year ){
    $ds += ((($_ % 4) == 0) && ( ($_ % 100) || (($_ % 400)==0) )) ? 366 : 365
    }

  # summ up the day of the months until the current
  for ( 0 .. $month-1 ){ $ds += $mdays[$_] ; }

  # add one if this is a leap year and we are after february
  if( ((($_ % 4) == 0) && ( ($_ % 100) || (($_ % 400)==0) )) && $month >1 ){ $ds++ }

  # summ up the days of the current months
  $ds += $day;

  # now convert all this stuff to seconds
  $ds *= 86400;

  # add hour, minute and seconds values
  $ds += $sec + 60*($min + 60*$hour);

  return $ds;
  }


sub normalize_url{
  shift;
  my $url = shift;

  if( $url =~ m{^http://([\w-\.]+):?(\d*)(/.*)?} ){
    my $host = $1; #URL host
    my $port = $2; #URL port
    my $path = $3; #URL path
    if( $host =~ m{\d+\.\d+\.\d+\.\d+} ){ # this is an ip number
      $host = $ip_host{$host} if defined $ip_host{$host};
      my $ourl = $url;
      $url = 'http://' . $host;
      $url .= ':' . $port if $port;
      $url .= $path if $path;
      webpage->log("NORMALIZED $ourl to $url");
      return $url;
      }else{
      return $url;
      }
    }else{
    return $url;
    }
  }


sub host {
  my $self = shift;

  if( ! defined $self->{'HOST'} ){
    webpage->normalize_url($self->url) =~ m{^http://([\w-\.]+):?(\d*)(/.*)?};
    $self->{'HOST'} = $1; #URL host
    $self->{'PATH'} = $3;
    if( $self->{'PATH'} =~ /\.(\d\w)+$/ ){ # path ends with file name
      $self->{'PATH'} =~ s{/[^/]*$}{/};    # delete the file name
      }else{
      $self->{'PATH'} .= '/' unless $self->{'PATH'} =~ m{/$};
      }
    }
  return $self->{'HOST'};
  }


sub path {
  my $self = shift;

  if( ! defined $self->{'PATH'} ){
    $self->host; # calculates also PATH
    }
  return $self->{'PATH'};
  }


sub url {
  my $self = shift;

  return $self->{'URL'};
  }


sub define_interface {
  shift; # class method
  my $if = shift;
  my $pattern = shift;

  if( ! $interfaces_defined ){
    @interfaces = ();
    %interfaces = ( );
    $interfaces_defined = 1;
    }
  push @interfaces , $if;
  $interfaces{$if} = $pattern;
  }


sub fetch_state {
  my $self = shift;
  my $state = shift;

  $self->{'FETCH_STATE'} = $state if defined $state;
  return $self->{'FETCH_STATE'};
  }


sub content_type {
  my $self = shift;

  if( ! defined $self->{'STRIPPED_CONTENT_TYPE'} ){
    $self->{'STRIPPED_CONTENT_TYPE'} = $self->{'HEADER'}->{'content-type'};
    $self->{'STRIPPED_CONTENT_TYPE'} =~ s/\s*;.*//;
    }
  return $self->{'STRIPPED_CONTENT_TYPE'};
  }


sub level{
  my $self = shift;
  my $level = shift;

  $self->{'LEVEL'} = $level
    if defined($level) && (!defined($self->{'LEVEL'}) || $self->{'LEVEL'} > $level);

  return $self->{'LEVEL'};
  }


sub schedule{
  my $self = shift;
  my $priority = shift;

  $priority = 0 unless defined $priority;
  return if $self->fetch_state ne 'FRESH';

  webpage->log('SCHEDULE ' . $self->url);
  push @schedule_list, { 'OBJECT' => $self , 'PRIORITY' => $priority };
  $self->fetch_state('SCHEDULED');
  }


sub next_page {
  my $sle = pop @schedule_list;

  return $sle->{'OBJECT'};
  }


sub destroy {
  my $self = shift;
  delete $self->{'CONTENT'}; # this is the most memory hungry part, but the rest is kept for reference
  delete $self->{'SPLIT'};
  }


sub cwd {
  shift;
  my $cwd = shift;

  if( defined($cwd) ){
    $save_directory = $cwd;
    }
  return $save_directory;
  }


sub proxy {
  my $self = shift;
  my $proxy = shift;

  $self->{'PROXY'} = $proxy if defined $proxy;
  $self->{'PROXY'};
  }


sub relate {
  my $self = shift;
  my $rpage = shift;
  my $file = $rpage->file;
  my $return;
  my $this_file;

  my @base_path = split( m{/} , $self->file );
  my @rela_path = split( m{/} , $file );

  if( $#base_path > -1 && $base_path[$#base_path] =~ /\./ ){
    $this_file = pop @base_path; # pop off file name
    }else{
    $this_file = '';
    }

  while( 1 ){
    last if $#base_path == -1 || $#rela_path == -1 || $base_path[0] ne $rela_path[0] ;
    shift @base_path;
    shift @rela_path;
    }

  while( $#base_path > -1 ){
    shift @base_path;
    unshift @rela_path , '..';
    }

  $return = join( '/' , @rela_path );
  $return = '' if $this_file && $this_file eq $return;
  return $return;
  }


sub split_html {
  my $self = shift;
  my $html = \$self->{'CONTENT'};
  my @tags = ();
  my $index,$cpos = 0;

  while( 1 ){
    my $text;

    $index = index( $$html, '<' , $cpos);
    if( $index > -1 ){
      $text = substr($$html,$cpos,$index-$cpos);
      }else{
      $text = substr($$html,$cpos);
      }
    if( $text ){
      push @tags , { TYPE     => 'TEXT' ,
                     CONTENT  => $text };
      }
    last if $index == -1;

    $index ++;# step over the '<'
    $cpos = index( $$html , '>' , $index );
    if( $cpos > -1 ){
      $text = substr($$html,$index,$cpos-$index);
      }else{
      $text = substr($$html,$index);
      }
    if( $text ){
      if( $text =~ /\!/ ){# this is a comment, and not a real tag
        # treat it as pure text
        push @tags , { TYPE    => 'TEXT' ,
                       CONTENT => "<$text>" };
#
# LATER WE SHOULD DEAL WITH <SCRIPT> </SCRIPT> TAGS AS TEXT AS WELL
# OR IMPLEMET A JAVASCRIPT ENGINE THAT CAN CALCULATE ALL THE POSSIBLE
# HREF VALUES THAT A JAVASCRIPT CAN CALCULATE (HA HA HA :-)
#
        }else{
        my @tagd = &tagdisa($text);
        push @tags , { TYPE    => 'TAG' ,
                       CONTENT =>  \@tagd };
        }
      }
    last if $cpos == -1;
    $cpos++;# step over the '>'
    }
  $self->{'SPLIT'} = \@tags;
  delete $self->{'CONTENT'};
  }

#
# Get a string containing a html tag and
# return a two element list. The first element of the list
# is the type of the tag (like A, B, P, H1). The second element is
# a reference to a hash. Each element contains the tag parameter name
# and value, like (HREF,http://www.mycom.com) for an A tag.
#
# THIS IS A FUNCTION NOT A METHOD USED ONLY INTERNALLY!!
sub tagdisa {
  my $tag = shift;
  my %params = ();

  $tag =~ s/^\s*//;         # delete leading spaces

  $tag =~ s/^(\/?\w+)//;    # get the type of the tag, NAME or /NAME
  my $type = lc $1;
  $tag =~ s/^\s*//;         # delete space after

  while( $tag ){
    $tag =~ s/^([^\s\=]+)//;         # get parameter name
    my $parn = lc $1;

    $tag =~ s/^\s*//;           # delete space after the parameter value

                                # if there is no =
    unless( $tag =~ s/^\=// ){  # then it is a parameter without value
      $params{$parn} = '';
      next;
      }

    $tag =~ s/^\s*//;           # delete space after the =

    my $parv = '';              # no parameter value so far
    if( $tag =~ s/^\"// ){      # starts with " like href="xxx"

      $tag =~ s/^([^"]*)//;     # anything until the trailing "
      $parv = $1;
      $tag =~ s/^\"//;          # delete the trailing "

      }else{                    # does not start with " like SIZE=3

      $tag =~ s/^(\S*)//;       # anything until space
      $parv = $1;

      }

    $tag =~ s/^\s*//;           # delete space after the parameter value

    $params{$parn} = $parv;
    }

  return ($type, \%params);
  }

sub rebuild_content {
  my $self = shift;
  my $tag;

  $self->{'CONTENT'} = ''; # we delete and the rebuild the content
  for $tag ( @{$self->{'SPLIT'}} ){
    if( $tag->{'TYPE'} eq 'TEXT' ){
      $self->{'CONTENT'} .= $tag->{'CONTENT'};
      }else{
      my $tagtype = $tag->{'CONTENT'}->[0];
      my $tags = $tag->{'CONTENT'}->[1];
      $self->{'CONTENT'} .= "<$tagtype";
      while( ($tagkw,$tagv) = each %{$tags} ){
        $self->{'CONTENT'} .= " $tagkw";
        $self->{'CONTENT'} .= "=\"$tagv\"" if defined $tagv;
        }
      $self->{'CONTENT'} .= '>';
      }
    }
  delete $self->{'SPLIT'};
  }


sub urel2abs {
  my $self = shift;
  my $relURL  = shift; # relative or absolute URL
  my $baseURL = $self->{'URL'};

  my $i,$return;

  return $relURL if $relURL =~ m{^\w+:};

  $baseURL = 'http://' . $baseURL unless $baseURL =~ m{^http://}i;

  $baseURL =~ m{^http://([\d\w-\.]+):?(\d*)(/.*)?(\#.*)?}i;
  my ($baseHost, $basePort, $basePath, $baseAnchor) = ( $1, $2, $3, $4);

  $basePath =~ s{^/}{};

  if( $relURL =~ m{^/} ){
    $return = 'http://' . $baseHost;
    $return .= ":$basePort" if $basePort ;
    $return .= $relURL;
    return $return;
    }

  if( $relURL =~ m{^\#} ){
    $return = 'http://' . $baseHost;
    $return .= ":$basePort" if $basePort ;
    $return .= "/$basePath";
    $return .= $relURL;
    return $return;
    }

  my @relList = split( m{/} , $relURL );
  my @absList = split( m{/} , $basePath );

  # trailing file name should be thrown away
  if( $#absList > -1 ){
    my $fileName = pop @absList;
    push @absList , $fileName unless $fileName =~ m{\.};
    }

  push @absList , @relList;

  @relList = ();

  while( $i = shift @absList ){
    if( $i eq '..' ){
      pop @relList;
      }else{
      push @relList , $i;
      }
    }
  $relURL = '/' . join( '/' , @relList );
  $return = 'http://' . $baseHost;
  $return .= ":$basePort" if $basePort ;
  $return .= $relURL;
  return $return;
  }


sub state_message {
  my $self = shift;
my %status_messages = (
  -1,  "Could not lookup server",
  -2,  "Could not open socket",
  -3,  "Could not bind socket",
  -4,  "Could not connect",
  -5,  "Retrieved file small",
  -6,  "Save file cannot be opened",
  -7,  "Page is too big.",

  200, "OK 200",
  201, "CREATED 201",
  202, "Accepted 202",
  203, "Partial Information 203",
  204, "No Response 204",
  301, "Found, but moved",
  302, "Found, but data resides under different URL (add a /)",
  303, "Method",
  304, "Not Modified",
  400, "Bad request",
  401, "Unauthorized",
  402, "PaymentRequired",
  403, "Forbidden",
  404, "Not found",
  500, "Internal Error",
  501, "Not implemented",
  502, "Service temporarily overloaded",
  503, "Gateway timeout ",
  600, "Bad request",
  601, "Not implemented",
  602, "Connection failed (host not found?)",
  603, "Timed out",
);
  return undef unless defined $self->{'STATE'};
  $self->{'STATE_MESSAGE'} = $status_messages{$self->{'STATE'}};
  }

sub get {
  my $self = shift;
  my $interface;
  my $buffer;

  return if $self->fetch_state eq 'RETRIEVED';

  my $URL  = $self->{'URL'};
  webpage->log("GET $URL");

  for( @proxies ){
    my $domain = $_->{'DOMAIN'};
    if( $self->url =~ m{$domain} ){
      $self->proxy($_->{'PROXY'});
      last;
      }
    }

  my $PROXY = $self->{'PROXY'};

  # split the URL to (host, port, path)
  if( $PROXY ){#using proxy

    $PROXY =~ m{(?:http://)?([\w-\.]+):?(\d*)};
    $host = $1;   #proxy host
    $port = $2;   #proxy port
    $path = $URL; #Using proxy the path is the full URL
    if ($port eq "") { $port = 8080; }

    }else{#if do not use proxy

    if ($URL =~ m#^http://([\w-\.]+):?(\d*)(/.*)?#) {
      $host = $1; #URL host
      $port = $2; #URL port
      if( $use_full_url ){
        $path = $URL; #send the full path
        }else{
        $path = $3; #URL path
        }
      }
    if ($path eq "") { $path = '/'; }
    if ($port eq "") { $port = 80; }

    }

  $AF_INET = 2;
  $SOCK_STREAM = 1;

  $sockaddr = 'S n a4 x8';

  if( $host_ip{$host} ){
    $thataddr = $host_ip{$host};
    }else{
    if (!(($name,$aliases,$type,$len,$thataddr) = gethostbyname($host))){
      $self->{'STATE'} = -1;
      return;
      }
    $host_ip{$host} = $thataddr;
    $ip_host{
      sprintf("%d.%d.%d.%d",ord(substr($thataddr,0,1)),
                              ord(substr($thataddr,1,1)),
                                ord(substr($thataddr,2,1)),
                                  ord(substr($thataddr,3,1)) ) } = $host
      unless $host =~ m{\d+\.\d+\.\d+\.\d+};
    }

  my $thataddr_ip_string = sprintf("%d.%d.%d.%d",ord(substr($thataddr,0,1)),
                              ord(substr($thataddr,1,1)),
                                ord(substr($thataddr,2,1)),
                                  ord(substr($thataddr,3,1)) );
  $interface = '';
  for( @interfaces ){
     if( $host =~ m{$interfaces{$_}} || $thataddr_ip_string =~ m{$interfaces{$_}} ){
       $interface = $_;
       last;
       }
     }
  if( ! $interface ){
    webpage->log("ERROR no interface defined for $host");
    webpage->log("QUITting");
    exit;
    }

  if( $host_ip{$interface} ){
    $thisaddr = $host_ip{$interface};
    }else{
    if (!(($name,$aliases,$type,$len,$thisaddr) = gethostbyname($interface))){
      webpage->log("ERROR can not bind local interface \"$interface\"");
      webpage->log("QUITting");
      $self->{'STATE'} = -1;
      return;
      }
    $host_ip{$interface} = $thisaddr;
    $ip_host{
      sprintf("%d.%d.%d.%d",ord(substr($thisaddr,0,1)),
                              ord(substr($thisaddr,1,1)),
                                ord(substr($thisaddr,2,1)),
                                  ord(substr($thisaddr,3,1)) ) } = $interface
      unless $interface =~ m{\d+\.\d+\.\d+\.\d+};
    }

  ($name,$aliases,$proto) = getprotobyname('tcp');

  $this = pack($sockaddr, $AF_INET, 0, $thisaddr);
  $that = pack($sockaddr, $AF_INET, $port, $thataddr);

  # Make the socket filehandle.
  if (!(socket(S, $AF_INET, $SOCK_STREAM, $proto))){
    $self->{'STATE'} = -2;
    $self->state_message;
    return;
    }

  # Give the socket an address
  if (!(bind(S, $this))) {
    $self->{'STATE'} = -3;
    $self->state_message;
    return;
    }

  my $time1 = time();
  if (!(connect(S,$that))) { 
    $self->{'STATE'} = -4;
    $self->state_message;
    return;
    }

  select(S); $| = 1; select(STDOUT);
  my $old_separator = $/; $/ = "\n";

  my $time2 = time();
  print S "GET $path HTTP/1.0\n";
  print S "User-Agent: $USERAGENT\n";
  print S "Accept: */*\n";

  if( $do_cookies ){
    my $ck = $self->list_cookies;
    if( $ck ){ #if there are any cookies
      print S "Cookie: ",$ck,"\n";
      webpage->log("COOKIE: $ck");
      }
    }

  my $auth = shift @{$self->{'AUTHLIST'}};
  if( defined $self->realm ){
    while( 1 ){
      last if $self->realm =~ $auth->{'REALM'};
      last unless defined($auth = pop @{$self->{'AUTHLIST'}});
      }
    }

  if( $auth->{'AUTH'} ){
    print S 'Authorization: Basic ' . $auth->{'AUTH'} . "\n";
    }

  print S "\n";
  binmode S;
  $response = <S>;
  chomp $response;
  ( $self->{'PROTOCOL'} , $self->{'STATE'} ) = split(/ /, $response);
  $self->state_message;
  webpage->log('HEADER State: ' . $self->{'STATE'});
  $self->{'CONTENT_LENGTH'} = 0;
  while(<S>){
    chomp;
    if( $_ eq chr(13) || $_ eq "" ){
      last;
      }

    while( s/\n$// || s/\r$// ){}# delete all \n and \r from the end
                                 # hopefully there are no such characters inside

    /([^\s\:]+):\s+(.*)/; # split the header line

    # store the header information in the header hash
    # if a header has multiple values then the second and the rest
    # is stored in the header continuation hash array
    if( defined $self->{'HEADER'}->{lc($1)} ){
      push @{$self->{'HEADERc'}->{lc($1)}} , $2;
      }else{
      $self->{'HEADER'}->{lc($1)} = $2;
      }
    webpage->log("HEADER $1: $2");
    }

  $self->set_all_cookies if $do_cookies;

  $self->{'CONTENT'} = '';
  # some servers report extraordinary large content-length (a few gigs), then it fails.
  if( $cl_believe &&
      $pagesizelimit &&
      $self->{'HEADER'}->{'content-length'} &&
      $pagesizelimit < $self->{'HEADER'}->{'content-length'} ){
    $self->{'STATE'} = -7;
    $self->state_message;
    return;
    }

  my $total = 0;
  for( $i=read(S,$buffer,1024) ; $i > 0 ; $i=read(S,$buffer,1024)){
    $total += $i; # count the total downloaded bytes
    if( $pagesizelimit && $pagesizelimit < $total ){
      $self->{'CONTENT'} = ''; # exit if file is too large
      $self->{'STATE'} = -7;
      $self->state_message;
      return;
      }
    $self->{'CONTENT'} .= $buffer;
    }

  my $time3 = time();
  close(S);
  $self->{'CONTENT_LENGTH'} = length $self->{'CONTENT'};

  my $dnrate;
  if(  $time3 - $time2 != 0 ){
    $dnrate = length($self->{'CONTENT'}) / ($time3 - $time2) / 128;
    if( $dnrate =~ /(\d+).(\d*)/ ){
      $dnrate = $1 . '.' . ($2 ? substr($2,0,2) : '00');
      }else{
      $dnrate .= '.00';
      }
    }else{ $dnrate = 'N/A ' }
  webpage->log('RETRIEVED ' . length($self->{'CONTENT'}) .
                 'bytes; Connect time=' . ($time2-$time1) .
                 'sec; Download time=' . ($time3 - $time2) .
                 'sec; Speed=' . $dnrate . 'Kbps; state=' . $self->{'STATE'});

  $/ = $old_separator;
  $self->fetch_state('RETRIEVED');
  if( $self->content_type ne 'text/html' ){
    $self->create_file;
    }
  return;
  }


sub realm {
  my $self = shift;

  my $www_authenticate;

  return $self->{'REALM'} if $self->{'REALM'};

  if( defined($www_authenticate=$self->{'HEADER'}->{'www-authenticate'}) ){
    if( $www_authenticate =~ /\s*(\w+)\s*realm=(.*)$/ ){
      $self->{'AUTH_TYPE'} = lc $1;
      $self->{'REALM'} = $2;
      }else{ return undef }
    }else{ return undef }
  }


sub auth_type{
  my $self = shift;

  $self->realm;
  return $self->{'AUTH_TYPE'};
  }


sub file {
  my $self = shift;
  return $self->{'FILE'} if defined $self->{'FILE'};

  $self->get; # get it to have the content type

  # method get calls create file for all non text/html mime types
  # which means calling this method recursively. So when it
  # calculates and returns to create_file and then returns to method get
  # and returns to here this parameter is already calculated...
  return $self->{'FILE'} if defined $self->{'FILE'};

  my $URL = webpage->normalize_url($self->url);
  my $path;
  my $port;

  if( $URL =~ m{^http://([\w-\.]+):?(\d*)(/.*)?} ){
    $host = $1; #URL host
    $port = $2; #URL port
    $path = $3; #URL path
    }
  if ($port eq '') { $port = 80; }
  if( $path =~ m{^/} ){ $path = substr($path,1) }

  # convert all characters that are active like ?g=1&h%20=14
  $path =~ tr/\?/\//;
  $path =~ tr/\=/\//;
  $path =~ tr/\&/\//; # to avoid too long file names
  $path =~ s/\$/\$24/g; # convert $ to $24
  # convert all other character to $xx where xx is hexa ASCII
  while( $path =~ m{([^\d\w./\$\-\_])} ){
    my $orc = $1;
    my $rep = sprintf("%02X",ord($orc));
    $orc = quotemeta $orc;
    $path =~ s/$orc/\$$rep/g;
    }
  $path =~ s{//}{/a/}g; # sometimes it happens that there are two neighbouring characters converted to /
  my @dlist = split(/\./ , $host);
  @dlist = reverse( @dlist );

  push @dlist , $port;

  if( $map_method eq 'simple' ){
    @dlist = ();
    }

  push @dlist , split(/\// ,$path);

  my $file_name = pop @dlist;

  push @dlist , $file_name;

  if( $file_name =~ /\.([^.]*)$/ ){
    my $extension = $1;
    my $pextarr = $mime_extension{$self->content_type};
    my $append = '.' . $pextarr->[0];
    for( @{$pextarr} ){
      my $pat = $_;
      if( substr($pat,0,1) eq '~' ){
        $pat = substr($pat,1);
        if( lc($extension) =~ /$pat/ ){
          $append = '';
          last;
          }
        }else{
        if( lc($extension) eq $_ ){
          $append = '';
          last;
          }
        }
      }

    $file_name .= $append;
    pop @dlist;
    push @dlist , $file_name;
    }else{
    if( defined($file_name=$self->{'HEADER'}->{'content-location'})){
      my @loca = split(/\//,$file_name);
      $file_name = pop @loca;
      }else{
      if( defined($mime_extension{$self->content_type}) ){
        $file_name = 'index.' . $mime_extension{$self->content_type}->[0];
        }else{ $file_name = 'index.html'; } # we are practically lost at this point
      }
    push @dlist , $file_name;
    }

  if( $map_method eq 'flat' ){
    $file_name =~ /\.([^.]*)$/;
    $self->{'FILE'} = $map_counter++ . ".$1";
    }else{
    $self->{'FILE'} = join('/',@dlist);
    }
  }


sub file_exists {
  my $self = shift;

  my $file = $self->cwd . '/' . $self->file;
  -e $file;
  }


sub create_file {
  my $self = shift;

  return if   $self->fetch_state eq 'SAVED';

  my $file = $self->cwd . '/' . $self->file;

  $file =~ s{\\}{/}g; # convert all \ to /
  $file =~ s{//}{/}g; #delete double slashes if any remained

  my @dlist = split( m{/} , $file);

  pop @dlist; #remove the trailing file name

  if( $#dlist == -1 ){ return; }#this is a simple file name in the current directory

  my $cwd = shift @dlist;#take the first subdirectory
  if( ! -d $cwd ){#if does not exist create it
    mkdir $cwd,$umask;
    }

  for( @dlist ){
    $cwd .= "/$_";#take the next subdirectory
    if( ! -d $cwd ){
      mkdir $cwd,$umask;  #if does not exist create it
      }
    }
  webpage->log("SAVED $file of type " . $self->content_type);
  my $FH = $self->{'URL'};
  open($FH,">$file") or die "$file can not be opened.";
  binmode $FH unless $self->content_type =~ /^text/;
  print $FH $self->{'CONTENT'};
  close $FH;
  $self->fetch_state('SAVED');
  $self->destroy;
  }


sub length {
  my $self = shift;
  return $self->{'CONTENT_LENGTH'};
  }


sub text_leaf {
  my $self = shift;
  my $url = $self->url;
    $self->{'CONTENT'} = <<END_HTML;
<HTML>
<HEAD>
<TITLE>Page not retrieved</TITLE>
<META HTTP-EQUIV="Refresh" CONTENT="1; URL=$url">
<META HTTP-EQUIV="Content-Type" CONTENT="text/html">
</HEAD>
<BODY>
<FONT FACE="Verdana" SIZE="2">
This page was not retrieved, and can be found at its original location: <A HREF="$url">$url</A>
</FONT>
</BODY>
</HTML>
END_HTML
  }


sub base64{
    shift;
    my $res = "";

    pos($_[0]) = 0;                          # ensure start at the beginning
    while ($_[0] =~ /(.{1,45})/gs) {
	$res .= substr(pack('u', $1), 1);
	chop($res);
    }
    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    $res;
}


sub text_badstate {
  my $self = shift;
  my $state_message = $self->state_message;
  my $status = $self->{'STATE'};
  my $proxy = $self->proxy;
  my $url = $self->url;
  $self->{'HEADER'}->{'content-type'} = 'text/html';
  $self->{'CONTENT'} = <<END_HTML;
<HTML>
<HEAD>
<TITLE>Page not retrieved</TITLE>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html">
</HEAD>
<BODY>
<FONT FACE="Verdana" SIZE="2">
This page was not retrieved, because the webserver
(or the proxy $proxy) returned an error code
instead of the resource.<p>
The error code was $status.<p>
The official explanation of this code is:<BR>
<center>
$state_message
</center>
<p>
You can try to retrieve the resource right now from <a href="$url">$url</a>
<p>
Good luck!
</FONT>
</BODY>
</HTML>
END_HTML
  }

sub text_redirect{
  my $self = shift;
  my $file = shift;

  $self->{'HEADER'}->{'content-type'} = 'text/html'; # it is probably already, but who knows
  $self->{'CONTENT'} = <<END_HTML;
<HTML>
<HEAD>
<TITLE>Page redirected</TITLE>
<META HTTP-EQUIV="Refresh" CONTENT="1; URL=$file">
<META HTTP-EQUIV="Content-Type" CONTENT="text/html">
</HEAD>
<BODY>
<FONT FACE="Verdana" SIZE="2">
This page has been moved to <A HREF="$file">$file</A>
</FONT>
</BODY>
</HTML>
END_HTML
  }

} #sub start_mirror(){
################## Subroutinen zum Mirrorn: Ende
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