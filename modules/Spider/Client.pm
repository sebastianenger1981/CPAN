#!/usr/bin/perl

package Spider::Client;
$VERSION = '1.5';
$DEBUG = "0";

require Exporter;
use IO::Socket;

@ISA = 'Exporter';
@EXPORT_OK = qw( sendNewConnectionRequest sendContentDeliverRequest pidfile);
@EXPORT = qw( sendNewConnectionRequest sendContentDeliverRequest pidfile);


########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class) = @_;
	my $object = bless {}, $class;
	return ($object);

};  # sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende


sub sendNewConnectionRequest() {

	my ($self, $host, $pid_file) = @_;

	# grundlegende funktionsaufrufe
	my $clientSocket = &createClientSocket($host);

	&writeSocket($clientSocket, "#####3381#####");
 	
	if ($DEBUG eq "1") {
		print "->>>> New Connection Establish Request send: \n\n";
	};

	my $information = &readSocket($clientSocket);
	
	my ( $WORKID, $STARTURL, $TYPE, $PAGEDEPTH, $LINKDEPTH, $CRAWLPAGES, $FOLLOWEXT, $STORELOCAL, $OUTPUT, $UPLOAD, $REGION_1, $REGION_2, $REGION_3, $REGION_4, $REGION_5, $REGION_6, $REGION_7, $REGION_8, $REGION_9, $REGION_10) = split('#', $information);
	
	&pidfile($pid_file, "", "delete");	
	&pidfile($pid_file, $WORKID, "write");
	
	if ($DEBUG eq "1") {
		
		print "\t\t\t #### DEBUG ####\n";
		print "\t Got the following Information for WORKID '$WORKID' from $host: \n";
		print "\t #################################\n";
		print "\t URL: $STARTURL\n";
		print "\t TYP: $TYPE\n";
		print "\t PDE: $PAGEDEPTH\n";
		print "\t LDE: $LINKDEPTH\n";
		print "\t CRA: $CRAWLPAGES\n";
		print "\t EXT: $FOLLOWEXT\n";
		print "\t STO: $STORELOCAL\n";
		print "\t OUT: $OUTPUT\n";
		print "\t UPL: $UPLOAD\n";
		print "\t PID: " . &pidfile($pid_file, "", "read") . "\n";
		print "\t #################################\n\n";
	 };

	if ($STARTURL eq "FINISHED") {
		print "\t ->>>> Spider::Client::sendNewConnectionRequest(): Server has run out of sites to scan - Finish now!\n";
		&logmsg("client.log", "Spider::Client::sendNewConnectionRequest(): Server has run out of sites to scan - Finish now!\n");
		exit(0);
	};
	
	close $clientSocket;
	
	%spider_work_config = (
		
		"WID" => "$WORKID",
		"URL" => "$STARTURL",
		"TYP" => "$TYPE",
		"PDE" => "$PAGEDEPTH",
		"LDE" => "$LINKDEPTH",
		"CRA" => "$CRAWLPAGES",
		"EXT" => "$FOLLOWEXT",
		"STO" => "$STORELOCAL",
		"OUT" => "$OUTPUT",
		"UPL" => "$UPLOAD",
		"R01" => "$REGION_1",
		"R02" => "$REGION_2",
		"R03" => "$REGION_3",
		"R04" => "$REGION_4",
		"R05" => "$REGION_5",
		"R06" => "$REGION_6",
		"R07" => "$REGION_7",
		"R08" => "$REGION_8",
		"R09" => "$REGION_9",
		"R10" => "$REGION_10",
	);

	return \%spider_work_config;
	undef %spider_work_config;

}; # sub sendNewConnectionRequest() {}



sub sendContentDeliverRequest() {

	($self, $CONNECT_CONFIG_HASHREF ) = @_;
	
	my %CONNECT_CONFIG = %$CONNECT_CONFIG_HASHREF;
	
	my $host		= %CONNECT_CONFIG->{"SERVER"};
	my $pid_file	= %CONNECT_CONFIG->{"PIDFILE"};
	my $filename	= %CONNECT_CONFIG->{"FILENAME"};
	my $filepath	= %CONNECT_CONFIG->{"FILEPATH"};
	my $checksum	= %CONNECT_CONFIG->{"CHECKSUM"};

	my $clientSocket = &createClientSocket($host);

	&writeSocket($clientSocket, "#####1177#####");
	
	if ($DEBUG eq "1") {
		print "->>>> Deliver Content Request send!\n";
	};

	my $pid = &pidfile($pid_file, "", "read");
	
	&writeSocket($clientSocket, "$pid#$filename#$checksum");

	open(RAR, "<$filepath") or &logmsg("client.log", "Spider::Client::sendContentDeliverRequest(): Failed to open RAR-File: '$filepath' !\n");  
	binmode(RAR);

	while ( $n = sysread(RAR, $buffer, 1400) ) {		 # former 1024 -> auch bei server.pm
		if ( defined($n) ) {
			print $clientSocket $buffer;
		} elsif ( !defined($n) ) {
			print "\t Transfer completed!\n";
		};
	};
	close RAR;	
	close $clientSocket;
	
	# erstelle neuen client und übertrage statusinformationen
	my $CLIENT = new IO::Socket::INET(
		PeerAddr => $host,
		PeerPort => "3382",
		Proto    => "tcp", 
		Timeout	 => "100",
	) or &logmsg("client.log", "Spider::Client::sendContentDeliverRequest(): Client Socket creation failure -> Remote Host: '$host' Port: '3382': '$!' '@!' \n");

	my $STATUS = <$CLIENT>;
	close $CLIENT;

	my (undef, $srv_filename, $srv_client_crc, $srv_server_crc, $srv_status) = split('#', $STATUS);
	
	if ( $srv_status eq "OK" ) {
		&pidfile($pid_file, "", "delete");
		print "\t -> Tranfer Succesful: '$filename' with  Checksum '$checksum' !\n";
	} elsif ( $srv_status eq "FAILURE" ) {
		print "\t -> Tranfer Failure: '$filename' - Retransmission !\n";
		&sendContentDeliverRequest("" , $CONNECT_CONFIG_HASHREF);
	} else {
		&pidfile($pid_file, "", "delete");
	};

	return 1;

}; # sub sendContentDeliverRequest() {}


sub sendErrorRequest() {
	
	my ($self, $host, $error_msg) = @_;

	my $clientSocket = &createClientSocket($host);

	&writeSocket($clientSocket, "$error_msg");
	print "Protokoll mismatch information send\n";

	close $clientSocket;
	return 1;

}; # sub sendErrorRequest() { }


sub readSocket(){

	my $socket = shift;

	my $msg = <$socket>;
	chop($msg);
	#chomp($msg);
	return $msg;

}; # sub readSocket(){}


sub writeSocket(){

	my $socket	= shift;
	my $msg		= shift;
	
	print $socket "$msg\n";
	return "$msg"; 

}; # sub writeSocket(){}


sub pidfile(){

	my ($pidfile, $msg, $type) = @_;
	
	if ( $type =~ /^read/i ) {
		
		undef $msg;
		open(PID, "<$pidfile");
			$msg = <PID>;
		close PID;
		chomp($msg);
		return $msg;

	} elsif ( $type =~ /^write/i ) {
	
		open(PID, ">$pidfile");
			print PID "$msg";
		close PID;
		return "PIDFILE WRITTEN!\n";
	
	} elsif ( $type =~ /^delete/i ) {

		unlink $pidfile;
		return "PIDFILE DELETED!\n";

	};
}; # sub pidfile(){ }


sub createClientSocket(){

	my ($host) = @_;

	my $socket = new IO::Socket::INET(
		PeerAddr => "$host",
		PeerPort => "3381",
		Proto    => "tcp", 
		Timeout	 => "100",
		) or die "Spider::Client::createClientSocket(): Cannot create Client Socket - Remote Host: '$host' Port: '3381' !\n";
	
	&logmsg("client.log", "Spider::Client::createClientSocket(): Client Socket created -> Remote Host: '$host' Port: '3381' \n");

	return $socket;

}; # sub createClientSocket(){}

################## Subroutinen zum loggen von nachrichten : Start
# Aufgabe: &logmsg() - protokolliere nachricht
# Rückgabe: nichts

sub logmsg(){

	my ($file, $msg ) = @_;
	
	open(WH,">>$file") or warn "Spider::Client::logmsg(): unable to stat: '$file' / ERRORMSG : '$!' / [". localtime() . "] LOGMSG: '$msg' !\n";
		print WH "[". localtime() . "] $msg";
	close WH;

}; # sub logmsg(){}
################## Subroutinen zum loggen von nachrichten :	Ende

########### Subroutine zur Testen, ob Verzeichnisse existieren:  Start
# Aufgabe: check_for_folders() - verzeichnis test 
# Rückgabe: 1

sub check_for_folders() {
	
	my ($self, $HASHREF) = @_;
	my %FOLDER_HASH = %{$HASHREF};
	
	while ( my ($key, $dir) = each(%FOLDER_HASH) ) {
		if ( -d $dir ) {
			# dir existiert und brauch nicht erstellt zu werden
		} elsif ( !-d $dir ) {
			# dir existiert NICHT und muss erstellt werden
			if ( !mkdir($dir, 0755) ) {
				# dir konnte mit mkdir() nicht erstellt werden
				# versuche nun mit windows und linux bordmitteln das verzeichnis zu erstellen
				system("mkdir $dir");
				system("mk $dir");
			} else {
				# $dir wurde erstellt	
			};
		};
	};

	while ( my ($key, $dir) = each(%FOLDER_HASH) ) {
		if ( !-d $dir ) {
			# dir existiert NICHT und konnte vorher auch nicht erstellt werden
			print "$0 -> Spider::Server::check_for_folders(): Directory '$dir' cannot be created -> Exit now!\n";
			&logmsg("server.log", "$0 -> Spider::Server::check_for_folders(): Directory '$dir' cannot be created !\n");
			exit;
		};
	};

	return 1;

}; # sub check_for_folders() {}
########### Subroutine zur Testen, ob Verzeichnisse existieren:  Ende


########### Subroutine zur Testen, ob Dateien existieren:  Start
# Aufgabe: check_for_files() - datei test 
# Rückgabe: 1

sub check_for_files() {
	
	my ($self, $HASHREF) = @_;
	my %FILE_HASH = %{$HASHREF};

	while ( my ($key, $file) = each(%FILE_HASH) ) {
		if ( -e $file ) {
			# $file existiert
		} elsif ( !-e $file ) {
			# file existiert nicht -> BEENDEN
			print "$0 -> Spider::Client::check_for_files(): File '$file' does not exist -> Exit now!\n";
			&logmsg("server.log", "$0 -> Spider::Client::check_for_files(): File '$file' does not exist -> Exit now!\n");
			exit;
		};
	};

	return 1;

}; # sub check_for_folders() {}
########### Subroutine zur Testen, ob Dateien existieren: Ende


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