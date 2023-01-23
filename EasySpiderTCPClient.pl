#!/usr/bin/perl -Imodules

# binde benötigte module ein
require "Spider\\HtmlParser.pl";
use Spider::ResultParser;
use Spider::Compression;
use Spider::Easyspider;	
use Spider::Easymirror;
use Spider::Config;
use Spider::Parser;
use Spider::Client;
use Spider::CRC;
use Getopt::Long;

# Hole übergebene Parameter
GetOptions( "config=s"	=> \$CONFIG );  

if (!defined($CONFIG)) {

	print "\nHELP: perl $0 --config=easyspider.cfg \n";
	exit;

}; 


#if ( time() > "1133700257" ) {
#	print "$0 Evaluation Periode is over !\n";
#	exit;
#};


# generiere neue objekte
my $EASYSPIDER		= Spider::Easyspider->new();
my $CONFIGURATION	= Spider::Config->new($CONFIG);
my $COMPR_OBJECT	= Spider::Compression->new();
my $CLIENT_OBJECT	= Spider::Client->new();
my $CRC_OBJECT		= Spider::CRC->new();

my $PIDFILE, $DIR_TO_COMPRESS, $WORK_RETURN_HASHREF , $COMPRESSED_RARFILE;

my $FOLLOW_FLAG		= $CONFIGURATION->cfg_followlinks;
my $STORE_FLAG		= $CONFIGURATION->cfg_storelocal;
my $STOREPATH		= $CONFIGURATION->cfg_storepath;
my $TMPPATH			= $CONFIGURATION->cfg_tmp;
my $LANG			= $CONFIGURATION->cfg_lang;
my $LINKDEPTH 		= $CONFIGURATION->cfg_ldepth;
my $PATHDEPTH 		= $CONFIGURATION->cfg_pdepth;
my $DEBUG 			= $CONFIGURATION->cfg_debug;
my $OUTPUTFORMAT 	= $CONFIGURATION->cfg_output;
my $OS				= $CONFIGURATION->cfg_os;
my $RAR_EXEC		= $CONFIGURATION->cfg_rar;
my $UNRAR_EXEC		= $CONFIGURATION->cfg_unrar;
my $PDF_CONVERT		= $CONFIGURATION->cfg_pdfconverter;
my $DOC_CONVERT		= $CONFIGURATION->cfg_docconverter;
my $PPT_CONVERT		= $CONFIGURATION->cfg_pptconverter;
my $XLS_CONVERT		= $CONFIGURATION->cfg_xlsconverter;
my $RTF_CONVERT		= $CONFIGURATION->cfg_rtfconverter;
my $TIMEOUT			= $CONFIGURATION->cfg_timeout;
my $USERAGENT		= $CONFIGURATION->cfg_useragent;
my $WORKTYPE		= $CONFIGURATION->cfg_worktype;
my $REGION_1_TAG	= $CONFIGURATION->cfg_region_1;
my $REGION_2_TAG	= $CONFIGURATION->cfg_region_2;
my $REGION_3_TAG	= $CONFIGURATION->cfg_region_3;
my $REGION_4_TAG	= $CONFIGURATION->cfg_region_4;
my $REGION_5_TAG	= $CONFIGURATION->cfg_region_5;
my $REGION_6_TAG	= $CONFIGURATION->cfg_region_6;
my $REGION_7_TAG	= $CONFIGURATION->cfg_region_7;
my $REGION_8_TAG	= $CONFIGURATION->cfg_region_8;
my $REGION_9_TAG	= $CONFIGURATION->cfg_region_9;
my $REGION_10_TAG	= $CONFIGURATION->cfg_region_10;
my $SERVER			= $CONFIGURATION->cfg_server;
my $ROBOTS			= $CONFIGURATION->cfg_robots;
my $USEPROXY		= $CONFIGURATION->cfg_useproxy;
my $PROXYURL		= $CONFIGURATION->cfg_proxyurl;
my $PROXYUSER		= $CONFIGURATION->cfg_proxyuser;
my $PROXYPASS		= $CONFIGURATION->cfg_proxypass;

my $METAKEYS_HASHREF = \%METAKEYS;
my $LINKS_ARRAYREF = \@LINKS;

chomp ( $HOSTNAME, $BODY, $TITLE, $FILETYPE, $HTML, $USERAGENT, $TIMEOUT ,$RTF_CONVERT ,$XLS_CONVERT ,$PPT_CONVERT ,$DOC_CONVERT ,$PDF_CONVERT ,$UNRAR_EXEC ,$RAR_EXEC );
chomp ( $URL, $FOLLOW_FLAG ,$STORE_FLAG ,$STOREPATH ,$CRAWLPAGES ,$LANG ,$LINKDEPTH ,$PATHDEPTH ,$DEBUG,$OUTPUTFORMAT , $OS ,$TMPPATH, $WORKTYPE, $UPLOAD );
chomp ( $GEWTEMPLATE, $XMLTEMPLATE ,$SQLTEMPLATE ,$TXTTEMPLATE ,$SERVER ,$REGION_10_TAG ,$REGION_9_TAG ,$REGION_8_TAG ,$REGION_7_TAG ,$REGION_6_TAG ,$REGION_5_TAG ,$REGION_4_TAG ,$REGION_3_TAG ,$REGION_2_TAG ,$REGION_1_TAG );

if ( $OS eq lc("windows") ) {
	$PIDFILE		= "$TMPPATH\\easyspider.client.pid";
} else {			
	$PIDFILE		= "$TMPPATH/easyspider.client.pid";
};

$start = localtime;
#$SIG{'INT'} = 'handler';

sub handler {
	
	$cur_time = localtime;	
	print "##############################\n";
	print "---------->\n";
	print "Start @: $start\n";
	print "End @:   $cur_time\n";
    print "Exit now!\n";
	exit;
};

#
#### check existence of folder and files
#

my $CLIENT_OBJECT_FOLDERS = {
	"1" => $TMPPATH	,
	"2" => $STOREPATH,
};

my $CLIENT_OBJECT_FILES = {
	"1" => $RAR_EXEC,
	"2" => $UNRAR_EXEC,
	"3" => $PDF_CONVERT,
	"4" => $DOC_CONVERT,
	"5" => $PPT_CONVERT,
	"6" => $XLS_CONVERT,
	"7" => $RTF_CONVERT,
};


system("perl resetscanlist.pl");

print "######################################################################\n";
print "############# EasySpiderTCPClient.pl -> Started working ##############\n";
print "######################################################################\n\n";

while( %$WORK_RETURN_HASHREF->{"URL"} !~ /FINISHED/io ){
	
	my $CLIENT_OBJECT_FOLDERS			= $CLIENT_OBJECT->check_for_folders( $CLIENT_OBJECT_FOLDERS );
	my $CLIENT_OBJECT_FILES				= $CLIENT_OBJECT->check_for_files( $CLIENT_OBJECT_FILES );

	$WORK_RETURN_HASHREF				= &new_connection();			
	$DIR_TO_COMPRESS					= $EASYSPIDER->scanner( &prepare_SCANNER_CONFIG($WORK_RETURN_HASHREF) );
	$COMPRESSED_RARFILE					= &deliver();
	
};

exit(0);


sub deliver() {
	
	my @RARFILENAME, $FILEPATH;

	if ( $OS eq lc("windows") ) {
		my $temp = $DIR_TO_COMPRESS;
		$temp =~ s/\\/#/g;
		@RARFILENAME = split('#', $temp );
	} else {
		@RARFILENAME = split('/', $DIR_TO_COMPRESS );
	};
	
	my $FILENAME = @RARFILENAME[$#RARFILENAME] . ".rar";
	
	if ( $OS eq lc("windows") ) {
		$FILEPATH = "$TMPPATH\\$FILENAME";
	} else {
		$FILEPATH = "$TMPPATH/$FILENAME";
	};

	$FILENAME = "[" . &pidfile($PIDFILE, "", "read") . "]" . $FILENAME;

	my %RAR_CONFIG = (
		"DIRTOCOMP"	=> $DIR_TO_COMPRESS,
		"TMPPATH"	=> $TMPPATH,
		"RAR_EXEC"	=> $RAR_EXEC,
		"FILENAME"	=> $FILENAME,
		"SPEED"		=> "1",
		"OS"		=> $OS,
	);
	
	my $RAR_CONFIG_HASHREF = \%RAR_CONFIG;

	print "\t -> Preparing Compression of '" . $DIR_TO_COMPRESS . "' to '$FILENAME'!\n";
	
	my $RARFILE = $COMPR_OBJECT->rar($RAR_CONFIG_HASHREF);
	my $CRC_RARFILE	= $CRC_OBJECT->CRCfromFile($RARFILE);

	undef $RAR_CONFIG_HASHREF, %RAR_CONFIG; 
	print "\t -> Compression of '$RARFILE' successful!\n";
	print "\t -> Now delivering '$RARFILE' to Server!\n";
	
	my %CONNECT_CONFIG = (
		"SERVER"	=> $SERVER,
		"PIDFILE"	=> $PIDFILE,
		"FILENAME"	=> $FILENAME,
		"FILEPATH"	=> $RARFILE,
		"CHECKSUM"	=> $CRC_RARFILE,
	);

	my $CONNECT_CONFIG_HASHREF	= \%CONNECT_CONFIG;
	my $deliverStatus			= $CLIENT_OBJECT->sendContentDeliverRequest( $CONNECT_CONFIG_HASHREF );
	return $RARFILE;

};


sub new_connection() {

	# rückgabe ist eine referenz mit den informationen zum scannen 
	my $WORK_HASHREF = $CLIENT_OBJECT->sendNewConnectionRequest($SERVER, $PIDFILE);

	# greife auf die werte des hashes zurück, auf die referenz verweisst
	my $WID = %$WORK_HASHREF->{"WID"};
	my $URL = %$WORK_HASHREF->{"URL"};
	my $TYP = %$WORK_HASHREF->{"TYP"};
	my $PDE = %$WORK_HASHREF->{"PDE"};
	my $LDE = %$WORK_HASHREF->{"LDE"};
	my $CRA = %$WORK_HASHREF->{"CRA"};
	my $EXT = %$WORK_HASHREF->{"EXT"};
	my $STO = %$WORK_HASHREF->{"STO"};
	my $OUT = %$WORK_HASHREF->{"OUT"};
	my $UPL = %$WORK_HASHREF->{"UPL"};
	my $R01 = %$WORK_HASHREF->{"R01"};
	my $R02 = %$WORK_HASHREF->{"R02"};
	my $R03 = %$WORK_HASHREF->{"R03"};
	my $R04 = %$WORK_HASHREF->{"R04"};
	my $R05 = %$WORK_HASHREF->{"R05"};
	my $R06 = %$WORK_HASHREF->{"R06"};
	my $R07 = %$WORK_HASHREF->{"R07"};
	my $R08 = %$WORK_HASHREF->{"R08"};
	my $R09 = %$WORK_HASHREF->{"R09"};
	my $R10 = %$WORK_HASHREF->{"R10"};

	return $WORK_HASHREF;

}; # sub new_connection() { }

sub prepare_SCANNER_CONFIG() {
	
	my $SCANNER_PRE_CONFIG = shift;
	
	%SCANNER_PRE_CONFIG = %{$SCANNER_PRE_CONFIG};

	my %SCANNER_CONFIG = (
	
		"OBJECT"		=> $EASYSPIDER,
		"URL"			=> %$SCANNER_PRE_CONFIG->{"URL"},	
		"FOLLOW_FLAG"	=> %$SCANNER_PRE_CONFIG->{"EXT"},	
		"STORE_FLAG"	=> %$SCANNER_PRE_CONFIG->{"STO"},
		"STOREPATH"		=> $STOREPATH,
		"TMPPATH"		=> $TMPPATH,
		"CRAWLPAGES"	=> %$SCANNER_PRE_CONFIG->{"CRA"},
		"LANG"			=> $LANG,
		"LINKDEPTH"		=> %$SCANNER_PRE_CONFIG->{"LDE"},
		"PATHDEPTH"		=> %$SCANNER_PRE_CONFIG->{"PDE"},
		"DEBUG"			=> $DEBUG,
   		"OUTPUTFORMAT"	=> %$SCANNER_PRE_CONFIG->{"OUT"},
		"OS"			=> $OS,
		"RAR_EXEC"		=> $RAR_EXEC,
		"UNRAR_EXEC"	=> $UNRAR_EXEC,
		"PDF_CONVERT"	=> $PDF_CONVERT,
		"DOC_CONVERT"	=> $DOC_CONVERT,
		"PPT_CONVERT"	=> $PPT_CONVERT,
		"XLS_CONVERT"	=> $XLS_CONVERT,
		"RTF_CONVERT"	=> $RTF_CONVERT,
		"TIMEOUT"		=> $TIMEOUT,
		"USERAGENT"		=> $USERAGENT,
		"HTML"			=> $HTML,
		"FILETYPE"		=> $FILETYPE,
		"LINKS"			=> $LINKS_ARRAYREF,
		"METAKEYS"		=> $METAKEYS_HASHREF,
		"TITLE"			=> $TITLE,
		"BODY"			=> $BODY,
		"HOSTNAME"		=> $HOSTNAME,
		"REGION_1_TAG"	=> %$SCANNER_PRE_CONFIG->{"R01"},
		"REGION_2_TAG"	=> %$SCANNER_PRE_CONFIG->{"R02"},
		"REGION_3_TAG"	=> %$SCANNER_PRE_CONFIG->{"R03"},
		"REGION_4_TAG"	=> %$SCANNER_PRE_CONFIG->{"R04"},
		"REGION_5_TAG"	=> %$SCANNER_PRE_CONFIG->{"R05"},
		"REGION_6_TAG"	=> %$SCANNER_PRE_CONFIG->{"R06"},
		"REGION_7_TAG"	=> %$SCANNER_PRE_CONFIG->{"R07"},
		"REGION_8_TAG"	=> %$SCANNER_PRE_CONFIG->{"R08"},
		"REGION_9_TAG"	=> %$SCANNER_PRE_CONFIG->{"R09"},
		"REGION_10_TAG" => %$SCANNER_PRE_CONFIG->{"R10"},
		"SERVER"		=> $SERVER,
		"TXTTEMPLATE"	=> $$TXTTEMPLATE,
		"SQLTEMPLATE"	=> $SQLTEMPLATE,
		"XMLTEMPLATE"	=> $XMLTEMPLATE,
		"GEWTEMPLATE"	=> $GEWTEMPLATE,
		"WORKTYPE"		=> %$SCANNER_PRE_CONFIG->{"TYP"},
		"UPLOAD"		=> %$SCANNER_PRE_CONFIG->{"UPL"},
		"CONFIG"		=> $CONFIG,
		"LINKCOUNT"		=> "-1",
		"ROBOTS"		=> $ROBOTS,
		"USEPROXY"		=> $USEPROXY,
		"PROXYURL"		=> $PROXYURL,
		"PROXYUSER"		=> $PROXYUSER,
		"PROXYPASS"		=> $PROXYPASS,

	); # my %SCANNER_CONFIG = ();
	
  my $SCANNER_CONFIG_HASHREF = \%SCANNER_CONFIG;
  return $SCANNER_CONFIG_HASHREF;

}; # sub prepare_SCANNER_CONFIG() {}


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