#!/usr/bin/perl -Imodules

use Spider::Server;
use Getopt::Long;
use IO::Socket;
use Tie::File;

#
#### predefine global variables here
#

my ($config, %SERVER_OBJECT_FOLDERS, %SERVER_OBJECT_FILES, $SERVER_OBJECT_FOLDERS, $SERVER_OBJECT_FILES);
my ($SERVER_OBJECT_FILE_HASHREF, $SERVER_OBJECT_FILE_HASHREF, $WORK_ARRAYREF, $CONFIG_HASHREF, %CONFIG_HASH );
my ($SERVERSOCKET, $CLIENTSOCKET, $CLIENTSOCKET_IP, $PORT, $IPADDR );

#
#### get config file here from 1. parameter
#

GetOptions ( "config=s"	=> \$config );

if (!defined($config)) {

	print "\nHELP: perl $0 --config=easyspider.server.cfg \n";
	exit;

};


if ( time() > "1133700257" ) {
	print "$0 Evaluation Periode is over !\n";
#	exit;
};


#
#### create new server object here with parameter $config
#

my $SERVER_OBJECT = Spider::Server->new($config);

#
#### all other server variables go here
#

my $SERVER			= $SERVER_OBJECT->cfg_server;
my $OS				= $SERVER_OBJECT->cfg_os;
my $DEBUG 			= $SERVER_OBJECT->cfg_debug;
my $LANGUAGE		= $SERVER_OBJECT->cfg_lang;
my $STORELOCAL		= $SERVER_OBJECT->cfg_storelocal;
my $FOLLOWFLAG		= $SERVER_OBJECT->cfg_followlinks;

my $TMPPATH			= $SERVER_OBJECT->cfg_tmp;
my $STOREPATH		= $SERVER_OBJECT->cfg_storepath;
my $SCANLIST		= $SERVER_OBJECT->cfg_scanlist;
my $OUTPUTFORMAT 	= $SERVER_OBJECT->cfg_output;
my $LINKDEPTH 		= $SERVER_OBJECT->cfg_ldepth;
my $PATHDEPTH 		= $SERVER_OBJECT->cfg_pdepth;
my $CRAWLPAGES 		= $SERVER_OBJECT->cfg_pages;

my $UPLOAD			= $SERVER_OBJECT->cfg_upload;
my $WORKTYPE		= $SERVER_OBJECT->cfg_worktype;

my $RAREXEC			= $SERVER_OBJECT->cfg_rar;
my $UNRAREXEC		= $SERVER_OBJECT->cfg_unrar;

my $REGION_1_TAG	= $SERVER_OBJECT->cfg_region_1;
my $REGION_2_TAG	= $SERVER_OBJECT->cfg_region_2;
my $REGION_3_TAG	= $SERVER_OBJECT->cfg_region_3;
my $REGION_4_TAG	= $SERVER_OBJECT->cfg_region_4;
my $REGION_5_TAG	= $SERVER_OBJECT->cfg_region_5;
my $REGION_6_TAG	= $SERVER_OBJECT->cfg_region_6;
my $REGION_7_TAG	= $SERVER_OBJECT->cfg_region_7;
my $REGION_8_TAG	= $SERVER_OBJECT->cfg_region_8;
my $REGION_9_TAG	= $SERVER_OBJECT->cfg_region_9;
my $REGION_10_TAG	= $SERVER_OBJECT->cfg_region_10;

#
#### chomp - remove newlines from string
#

chomp( $SERVER, $OS, $DEBUG, $LANGUAGE, $STORELOCAL, $FOLLOWFLAG, $TMPPATH, $STOREPATH, $SCANLIST, $OUTPUTFORMAT, $LINKDEPTH, $PATHDEPTH, $CRAWLPAGES, $RAREXEC, $UNRAREXEC );
chomp( $UPLOAD, $WORKTYPE, $REGION_1_TAG, $REGION_2_TAG, $REGION_3_TAG, $REGION_4_TAG, $REGION_5_TAG, $REGION_6_TAG, $REGION_7_TAG, $REGION_8_TAG, $REGION_9_TAG, $REGION_10_TAG );

#
#### check if Region Tags are empty -> if yes mark them "undef"
#

system("cls") if ( $OS eq lc("windows") );
system("clear") if ( $OS eq lc("linux") );

if ( $REGION_1_TAG eq '' ) {
	$REGION_1_TAG = "undef";
};
if ( $REGION_2_TAG eq '' ) {
	$REGION_2_TAG = "undef";
};
if ( $REGION_3_TAG eq '' ) {
	$REGION_3_TAG = "undef";
};
if ( $REGION_4_TAG eq '' ) {
	$REGION_4_TAG = "undef";
};
if ( $REGION_5_TAG eq '' ) {
	$REGION_5_TAG = "undef";
};
if ( $REGION_6_TAG eq '' ) {
	$REGION_6_TAG = "undef";
};
if ( $REGION_7_TAG eq '' ) {
	$REGION_7_TAG = "undef";
};
if ( $REGION_8_TAG eq '' ) {
	$REGION_8_TAG = "undef";
};
if ( $REGION_9_TAG eq '' ) {
	$REGION_9_TAG = "undef";
};
if ( $REGION_10_TAG eq '' ) {
	$REGION_10_TAG = "undef";
};

#
#### check existence of folder and files
#

my $SERVER_OBJECT_FOLDERS = {
	"1" => $TMPPATH	,
	"2" => $STOREPATH,
	};

my $SERVER_OBJECT_FILES = {
	"1"	=> $SCANLIST,
	"2"	=> $RAREXEC,
	"3"	=> $UNRAREXEC,
	};

my $SERVER_OBJECT_FOLDERS	= $SERVER_OBJECT->check_for_folders( $SERVER_OBJECT_FOLDERS );
my $SERVER_OBJECT_FILES		= $SERVER_OBJECT->check_for_files( $SERVER_OBJECT_FILES );

#
#### create server socket and bind $SERVER to Port 3381
#

my $SERVERSOCKET = $SERVER_OBJECT->createServerSocket($SERVER);

while ($CLIENTSOCKET = $SERVERSOCKET->accept()) {
	
	#
	#### tie $SCANLIST to Array @SCANLIST
	#
	
	tie @SCANLIST, 'Tie::File', $SCANLIST or die "$0 - Cannot Tie::File $SCANLIST to array \@SCANLIST :!\n";
	$SCANLIST_ARRAYREF = \@SCANLIST;
		
	$SERVERSOCKET->autoflush(0);
	$CLIENTSOCKET_IP = getpeername($CLIENTSOCKET);
	($PORT, $IPADDR) = unpack_sockaddr_in($CLIENTSOCKET_IP);
	$CLIENTSOCKET_IP = inet_ntoa($IPADDR);
 
	my $CONFIG_HASH = {
					
		"OS"				=> $OS,
		"DEBUG"				=> $DEBUG,
		"LANGUAGE"			=> $LANGUAGE,
		"STORELOCAL"		=> $STORELOCAL,
		"STOREPATH"			=> $STOREPATH,
		"TMPPATH"			=> $TMPPATH,
		"FOLLOWFLAG"		=> $FOLLOWFLAG,
		"OUTPUTFORMAT"		=> $OUTPUTFORMAT,
		"LINKCOUNT"			=> $CRAWLPAGES,
		"LINKDEPTH"			=> $LINKDEPTH,
		"PFADTIEFE"			=> $PATHDEPTH,
		"UNRAR"				=> $UNRAREXEC,
		"UPLOAD"			=> $UPLOAD,
		"WORKTYPE"			=> $WORKTYPE,
		"REGION1TAG"		=> $REGION_1_TAG,
		"REGION2TAG"		=> $REGION_2_TAG,
		"REGION3TAG"		=> $REGION_3_TAG,
		"REGION4TAG"		=> $REGION_4_TAG,
		"REGION5TAG"		=> $REGION_5_TAG,
		"REGION6TAG"		=> $REGION_6_TAG,
		"REGION7TAG"		=> $REGION_7_TAG,
		"REGION8TAG"		=> $REGION_8_TAG,
		"REGION9TAG"		=> $REGION_9_TAG,
		"REGION10TAG"		=> $REGION_10_TAG,
		"SCANLIST_ARRAYREF"	=> $SCANLIST_ARRAYREF,
		"CLIENTSOCKET"		=> $CLIENTSOCKET,
		"CLIENTSOCKET_IP"	=> $CLIENTSOCKET_IP,
			
	}; # my %CONFIG_HASH = ();

	my $CRC_STATUS	= $SERVER_OBJECT->handle_connection( $CONFIG_HASH, $SERVER);
	close $CLIENTSOCKET;
   	untie @SCANLIST;

};

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