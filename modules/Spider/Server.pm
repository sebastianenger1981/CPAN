#!/usr/bin/perl

package Spider::Server;
$VERSION = '1.98';

use Spider::Compression;
use Spider::CRC;
use IO::Socket;

# TODO: 
#  - generateTransmissionString(): infor aus config holen, welche daten der client scannen soll
#  - handle_connection(): nur informationen ausgeben, wenn debug gesetzt ist
#  - Verbindung zu sql server herstellen, und dort alle daten hinterlegen: wann wo was gescannt wurde
#


########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class, $config) = @_;
	our %config = &read_easyspider_server_config($config);
	my $object = bless {}, $class;
	return $object;

}; # sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende


########### Subroutine zur Testen, ob Verzeichnisse existieren:  Start
# Aufgabe: check_for_folders() - verzeichnis test 
# Rückgabe: 1

sub check_for_folders() {
	
	my ($self, $HASHREF) = @_;
	my %FOLDER_HASH = %$HASHREF;
	
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
			print "$0 -> Spider::Server::check_for_folders(): '$dir' cannot be created -> Exit now (Maybe you loaded false config) !\n";
			&logmsg("server.log", "$0 -> Spider::Server::check_for_folders(): '$dir' cannot be created !\n");
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
	my %FILE_HASH = %$HASHREF;

	while ( my ($key, $file) = each(%FILE_HASH) ) {
		if ( -e $file ) {
			# $file existiert
		} elsif ( !-e $file ) {
			# file existiert nicht -> BEENDEN
			print "$0 -> Spider::Server::check_for_files(): '$file' does not exist -> Exit now (Maybe you loaded false config) !\n";
			&logmsg("server.log", "$0 -> Spider::Server::check_for_files(): $file does not exist -> Exit now!\n");
			exit;
		};
	};

	return 1;

}; # sub check_for_folders() {}
########### Subroutine zur Testen, ob Dateien existieren: Ende


################## Subroutinen zum Verarbeiten der eingehenden Verbindungen : Start
# Aufgabe: &handle_connection() - handle die einkommenden verbindungen
# Rückgabe: nichts

sub handle_connection() {

	my ($self, $CONFIG_HASHREF, $host ) = @_;
	my %CONFIG_HASH = %$CONFIG_HASHREF;

	my $ClientSocket	= %CONFIG_HASH->{"CLIENTSOCKET"};
	my $ClientSocket_ip	= %CONFIG_HASH->{"CLIENTSOCKET_IP"};
	my $storepath		= %CONFIG_HASH->{"STOREPATH"};
	my $tmppath			= %CONFIG_HASH->{"TMPPATH"};
	my $unrar			= %CONFIG_HASH->{"UNRAR"};
	my $OS				= %CONFIG_HASH->{"OS"};
	my $FN;

	# hier wird die verbindung bearbeitet
	$ClientSocket->autoflush(0);

	my $ClientSocketMsg = &readSocket($ClientSocket);
	my $lenght = $lenght + &getStringLenght($ClientSocketMsg);
			
	if ( $ClientSocketMsg eq "#####3381#####" ) {		# neuer verbindungsaufbau
		
		print "[$ClientSocket_ip]\n";
		print "\t -=# New Session Established #=- \n";
		print "\t -> Sending Information to Client!\n";
		
		# übertragunginformationen vorbereiten
		my $transmission = &generateTransmissionString($CONFIG_HASHREF, $id);
		$lenght = $lenght + &getStringLenght($transmission);
		
		# aktuelle zeitinformationen holen
		my $now = time();
		my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($now);
		$year +=1900;
		
		&writeSocket($ClientSocket, $transmission );
		print "\t -> Client got Information for WorkID '$id'!\n";
		print "\t -> Updating Status Information File!\n";
		
		# statusinformationen hinterlegen
		undef @t_temp, $temp, $id, $transmission, $now;
		print "\t -> Transmission done: " . $lenght/1024 . " KB already transfered !\n\n";

		return 1;

	} elsif ( $ClientSocketMsg eq "#####1177#####" ) {	# abliefern von content

		print "[$ClientSocket_ip]\n";
		print "\t -=# Deliver Content #=-\n";	
		
		my $temp = &readSocket($ClientSocket);
		my ($work_id, $filename, $checksum) = split('#', $temp);
		
		print "\t -> Recieving: '$filename' / WorkID: '$work_id' !\n";
	   	 
		if ($OS =~ /windows/i) {
			$FN = "$tmppath\\$filename";
			print "\t -> Open: '$FN' for writing !\n";
			unlink $FN;
			open(FROMCLIENT, ">$FN") or &logmsg("server.log","Spider::Server.pm: Could not open $FN for writing: $!\n");
		} elsif ($OS =~ /linux/i) {
			$LFN = "$tmppath/$filename";
			print "\t -> Open: '$LFN' for writing !\n";
			unlink $LFN;
			open(FROMCLIENT, ">$LFN") or &logmsg("server.log","Spider::Server.pm: Could not open $LFN for writing: $!\n");
		} else {
			# asume linux based OS
			$LFN = "$tmppath/$filename";
			print "\t -> Open: '$LFN' for writing !\n";
			unlink $LFN;
			open(FROMCLIENT, ">$LFN") or &logmsg("server.log","Spider::Server.pm: Could not open $LFN for writing: $!\n");
		};
		
		binmode(FROMCLIENT);
	
		while ( $remote_fh = sysread( $ClientSocket, $buffer, 1400) ) {
			if ( defined($remote_fh) ) {
				$lenght = $lenght + &getStringLenght($buffer);
				print FROMCLIENT $buffer;
			};
		};
	
		close (FROMCLIENT);
		print "\t -> Transmission done: " . $lenght/1024 . " KB already transfered !\n";

		if ( lc( $OS ) eq "windows" ) {
			$FN = "$tmppath\\$filename";
		} elsif (lc( $OS ) eq "linux" ) {
			$FN = "$tmppath/$filename";
		} else {
			$FN = "$tmppath/$filename";
		};

		my $CRC_OBJECT	= Spider::CRC->new();
		my $CRC_RARFILE	= $CRC_OBJECT->CRCfromFile($FN);
		
		# erstelle neuen tcp server für eine Verbindung
		my $CRC_SERVER = new IO::Socket::INET(
			LocalHost => $host,
			LocalPort => '3382',
			Proto => 'tcp',
			Listen => 1,
			Reuse => 1,
			Type => SOCK_STREAM,
		) or &logmsg("server.log", "Spider::Client::handle_connection(): Small Server Socket Creation Failure: '$!' '@!'\n");
	 	
		# empfange einen connection() request
		my $COM = $CRC_SERVER->accept();
		
		# sende die statusinformationen aus für ein erfolgreiches empfangen
		if ( $checksum eq $CRC_RARFILE ) {
			print "\t -> CRC Match: '$CRC_RARFILE' !\n";
			print "\t -> Sending Status: 'CRC OK'!\n";
			print $COM "#$filename#$checksum#$CRC_RARFILE#OK#\n";	

			my %UNRAR_CFG = (
				"RARFILE"		=> $FN,
				"FILENAME"		=> $filename,
				"STOREPATH"		=> $storepath,
				"UNRAR"			=> $unrar,
				"OS"			=> $OS,
			);

			my $UNRAR_CFG		= \%UNRAR_CFG;
			my $COMPR_OBJECT	= Spider::Compression->new();
			my $UNRARFILE		= $COMPR_OBJECT->unrar($UNRAR_CFG);
			print "\t -> Uncompressing: '$UNRARFILE'!\n";

		# sonst fehlerhafte
		} else {
			print "\t -> CRC Failure: '$CRC_RARFILE' !\n";
			print "\t -> Sending Status: 'CRC Failure'!\n\n";
			print $COM "#$filename#$checksum#$CRC_RARFILE#FAILURE#\n";	
		};
		
		close $CRC_SERVER;
		return 1;

	} else {
	
		print "[$ClientSocket_ip]\n";
		print "\t -=# Protocoll Mismatch #=-\n";
		&writeSocket($ClientSocket, "-=$ClientSocketMsg=- [$ClientSocket_ip]: Protokoll mismatch - Closing Connection\n");
		close $ClientSocket;
		&logmsg("server.log", "-=$ClientSocketMsg=- [$ClientSocket_ip]: Protokoll mismatch !\n");
		$lenght = $lenght + &getStringLenght("-=$ClientSocketMsg=- [$ClientSocket_ip]: Protokoll mismatch - Closing Connection\n");
		print "\t -> Transmission done: " . $lenght/1024 . " KB already transfered !\n\n";
		
		return 1;

	};

};	# sub handle_connection() {
################## Subroutinen zum Verarbeiten der eingehenden Verbindungen : ENDE

################## Subroutinen zum erstellen des Server Sockets : Start
# Aufgabe: &createServerSocket() - erstelle server socket
# Rückgabe: $socket

sub createServerSocket(){

	my ($self, $host) = @_;
	my $socket = new IO::Socket::INET(
		LocalHost => $host,
		LocalPort => '3381',
		Proto => 'tcp',
		Listen => 65535,
		Reuse => 1,
		Type => SOCK_STREAM,
        ) or die "Could not create Server Socket: $!\n" . &logmsg("server.log","Could not create Server Socket: $!\n")  unless defined($socket);
	&logmsg("server.log","EasySpiderTCPServer bind to Port '3381' on Host '$host' successful: Socket created!\n");
	
	print "##########################################\n";
	print "-=# EasyServer.pl started on Port 3381 #=-\n";
	print "##########################################\n";

	return $socket;

}; # sub createServerSocket(){}
################## Subroutinen zum erstellen des Server Sockets : Ende


################## Subroutinen zum loggen von nachrichten : Start
# Aufgabe: &logmsg() - protokolliere nachricht
# Rückgabe: nichts

sub logmsg(){

	my ($file, $msg ) = @_;
	
	open(WH,">>$file") or warn "Spider::Server::logmsg(): unable to stat: '$file' / ERRORMSG : '$!' / [". localtime() . "] LOGMSG: '$msg' !\n";
		print WH "[". localtime() . "] $msg";
	close WH;

}; # sub logmsg(){}
################## Subroutinen zum loggen von nachrichten :	Ende


################## Subroutinen zum Erstellen der Nachricht : Start
# Aufgabe: &generateTransmissionString() - erstelle nachricht für den client
# Rückgabe: nachricht

sub generateTransmissionString(){

	my ($CONFIG_HASHREF, $WORKID) = @_;
	my ($SCANURL);

	my %CONFIG_HASH = %$CONFIG_HASHREF;
	my $SCANLIST_REF = %CONFIG_HASH->{"SCANLIST_ARRAYREF"};
	
	# eine ID für die übertragung erstellen, damit aktionen rückverfolgbar sind
	my $id = &ID();

	$SCANURL = get_entry(%CONFIG_HASH->{"SCANLIST_ARRAYREF"}, $id);
	
	# wenn SCANLIST eine "1" ist, dann bedeutet das, dass der server fertig mit der verteilung der aufgaben ist
	# und keine weiteren aufgaben verteilt werden brauche -> der client kann sich also beenden

	if ($SCANURL eq "1") {
		$SCANURL = "FINISHED";	
	};
				
	my $STARTURL	= $SCANURL;
	my $TYPE		= %CONFIG_HASH->{"WORKTYPE"};
	my $PAGEDEPTH	= %CONFIG_HASH->{"PFADTIEFE"};
	my $LINKDEPTH	= %CONFIG_HASH->{"LINKDEPTH"};
	my $CRAWLPAGES	= %CONFIG_HASH->{"LINKCOUNT"};
	my $FOLLOWEXT	= %CONFIG_HASH->{"FOLLOWFLAG"};
	my $STORELOCAL	= %CONFIG_HASH->{"STORELOCAL"};
	my $OUTPUT		= %CONFIG_HASH->{"OUTPUTFORMAT"};
	my $UPLOAD		= %CONFIG_HASH->{"UPLOAD"};
	my $REGION_1	= %CONFIG_HASH->{"REGION1TAG"};
	my $REGION_2	= %CONFIG_HASH->{"REGION2TAG"};
	my $REGION_3	= %CONFIG_HASH->{"REGION3TAG"};
	my $REGION_4	= %CONFIG_HASH->{"REGION4TAG"};
	my $REGION_5	= %CONFIG_HASH->{"REGION5TAG"};
	my $REGION_6	= %CONFIG_HASH->{"REGION6TAG"};
	my $REGION_7	= %CONFIG_HASH->{"REGION7TAG"};
	my $REGION_8	= %CONFIG_HASH->{"REGION8TAG"};
	my $REGION_9	= %CONFIG_HASH->{"REGION9TAG"};
	my $REGION_10	= %CONFIG_HASH->{"REGION10TAG"};

	my $transmission = "$id#$STARTURL#$TYPE#$PAGEDEPTH#$LINKDEPTH#$CRAWLPAGES#$FOLLOWEXT#$STORELOCAL#$OUTPUT#$UPLOAD#$REGION_1#$REGION_2#$REGION_3#$REGION_4#$REGION_5#$REGION_6#$REGION_7#$REGION_8#$REGION_9#$REGION_10";
	return $transmission;

}; # sub generateTransmissionString(){ }
################## Subroutinen zum Erstellen der Nachricht :

################## Subroutinen zum ausgeben der aktuellen workeinträge: Start
# Aufgabe: &get_entry() - gib eintrag zum scannen aus array aus
# Rückgabe: URL, die gescannt werden soll

sub get_entry() {
		
	my $REF = shift;
	my $ID	= shift;

	my $count, $fin, $entry, $status, $url, $return_url;
	$fin = "0";

	foreach $entry (@$REF) {
			
		$count++;	
		($status, $url) = split(/#/o, $entry);
		chomp($status, $url);
		
		if ($fin ne "1") {
		
			# wenn status 'WORKING' oder 'COMPLETE' matcht, dann nix weitermachen mit nächstem eintrag
			# bis einer gefunden wurde, der nicht den og. kritieren entspricht

			if ( $status =~ /^WORKING/ig ) {
			} elsif ( $status =~ /^COMPLETE/ig ) {
			} elsif ( $status =~ /^ENDE/ig ) {
				print "\t ############ !!! WARNING !!! SCANLIST: - NO MORE SITES TO SCAN \n";  # \a
				&logmsg("server.log", "$0 -> Spider::Server::get_entry(): !!! WARNING !!! SCANLIST: - NO MORE SITES TO SCAN\n");
				return 1;
			} elsif ( $status =~ /^END/ig ) {
				print "\t ############ !!! WARNING !!! SCANLIST: - NO MORE SITES TO SCAN \a\n";&logmsg("server.log", "$0 -> Spider::Server::get_entry(): !!! WARNING !!! SCANLIST: - NO MORE SITES TO SCAN\n");
				return 1;
			} else {
				if ( $url =~ /\w{4,}/ig ) {
					$fin = "1";
					$entry = "WORKING{'$ID'}#$url";
					$return_url = $url;
				} else {
					print "$0 -> Spider::Server::get_entry(): @SCANLIST ARRAY Status: '$status' and Url: '$url' -> EMPTY OR MISMATCH!\n";
					&logmsg("server.log", "$0 -> Spider::Server::get_entry(): @SCANLIST ARRAY Status: '$status' and Url: '$url' -> EMPTY OR MISMATCH!\n");
				};
			};
		};
	};

	return $return_url;

}; # sub get_entry() { }
################## Subroutinen zum ausgeben der aktuellen workeinträge: ENDE

################## Subroutinen zum Lesen einer Nachricht von einem Socket: Start
# Aufgabe: &readSocket() - lese was vom socket
# Rückgabe: gelesene nachricht

sub readSocket(){

	my $socket = shift;
	my $msg = <$socket>;
	chop($msg);
	return $msg;

}; # sub readSocket(){}
################## Subroutinen zum Lesen einer Nachricht von einem Socket: Ende

################## Subroutinen zum Übertragen einer Nachricht über einen Socket: Start
# Aufgabe: &writeSocket() - schreibe was über den socket
# Rückgabe: übertragenene nachricht

sub writeSocket(){

	my $socket	= shift;
	my $msg		= shift;
	print $socket "$msg\n";
	return "$msg"; 

}; # sub writeSocket(){}
################## Subroutinen zum Übertragen einer Nachricht über einen Socket: Ende

################## Subroutinen zum Auslesen der Länge eines Strings: Start
# Aufgabe: &getStringLenght() - berechne stringlänge
# Rückgabe: länge des strings in int

sub getStringLenght(){
	
	my $string = shift;
	return length($string);

}; # sub getStringLenght(){}
################## Subroutinen zum Auslesen der Länge eines Strings: Ende


################## Subroutinen zum Erstellen der WORK ID: Start
# Aufgabe: &ID() - erstelle work id
# Rückgabe: id, 10 stellig

sub ID() {
	
	my (@alpha, @number);
	
	@alpha	= ( "A",  "B", "C", "D", "E", "F", "G", "H" );
		
		$r1 = int(rand(7))+1;
		$r2 = int(rand(7))+1;
		$r3 = int(rand(7))+1;
		$r4 = int(rand(7))+1;
		$r5 = int(rand(7))+1;
	
	@number = ( "0",  "1", "2", "3", "4", "5", "6", "7", "8", "9" );
	
		$rr1 = int(rand(9))+1;
		$rr2 = int(rand(9))+1;
		$rr3 = int(rand(9))+1;
		$rr4 = int(rand(9))+1;
		$rr4 = int(rand(9))+1;

	return "@alpha[$r1]@number[$rr1]@alpha[$r2]@number[$rr2]@alpha[$r3]@number[$rr3]@alpha[$r4]@number[$rr4]@alpha[$r5]@number[$rr5]";

}; # sub ID() {}
################## Subroutinen zum Erstellen der WORK ID: Ende


################## Subroutinen zum Auslesen der Configuration: Start
# Aufgabe: &read_easyspider_server_config - lese config in speicher und gib config hash zurück
# Rückgabe: %config_hash mit gespeicherten konfigurationsoptionen

sub read_easyspider_server_config {

	my ($config) = @_;
	
	open(CONFIG, "<$config") or die "Spider::Server.pm: &read_easyspider_server_config(): Cannot read config file \'$config\': $!\n";
		my @config = <CONFIG>;
	close CONFIG;

	foreach $line (@config){
		
		# überspringe kommentare 
		next if $line =~ /^#/;				
		
		# splitte config eintrag an dem zeichen '=' in option und flag auf 
		($option,$flag)	= split('=',$line);		
		$temp_flag = $flag;

		# entferne leerzeichen aus der variabel
		$option =~ s/ //g;				
		$flag =~ s/ //g;
			
		if ($option =~ /PATHDEPTH/ig){
			$DEPTH_Path = $flag;
		} elsif ($option =~ /LINKDEPTH/ig){
			$DEPTH_Link = $flag;
		} elsif ($option =~ /CRAWLPAGES/ig){
			$CRAWLPAGES = $flag;
		} elsif ($option =~ /FOLLOWEXT/ig){
			$FOLLOW_EXTERN_LINKS = $flag;
		} elsif ($option =~ /STORELOCAL/ig){
			$STORE_Local = $flag;
		} elsif ($option =~ /STOREPATH/ig){
			$STORE_Path = $flag;
		} elsif ($option =~ /DESCRIPTION/ig){
			$DESC = $flag;
		} elsif ($option =~ /KEYWORDS/ig){
			$KEYW = $flag;
		} elsif ($option =~ /TITLE/ig){
			$TITLE = $flag;
		} elsif ($option =~ /DATE/ig){
			$DATE = $flag;
		} elsif ($option =~ /BODY/ig){
			$BODY = $flag;
		} elsif ($option=~ /DEBUG/ig){
			$DEBUG = $flag;
		} elsif ($option =~ /OUTPUTFORMAT/ig) {
			$OUTPUT = $flag;
		} elsif ($option =~ /LANGUAGE/ig) {
			$LANG = $flag;
		} elsif ($option =~ /OS/ig) {
			$OS = $flag;	
		} elsif ($option =~ /TMPPATH/ig) {
			$TMP = $flag;	
		} elsif ($option =~ /RAR/ig) {
			$RAR = $flag;
		} elsif ($option =~ /UNCOMPRESS/ig) {
			$UNRAR = $flag;	
		} elsif ($option =~ /SCANLIST/ig) {
			$SCANLIST = $flag;	
		} elsif ($option=~ /REGION_1/ig){
			$REGION_1 = $flag;
		} elsif ($option=~ /REGION_2/i){
			$REGION_2 = $flag;
		} elsif ($option=~ /REGION_3/ig){
			$REGION_3 = $flag;
		} elsif ($option=~ /REGION_4/ig){
			$REGION_4 = $flag;
		} elsif ($option=~ /REGION_5/ig){
			$REGION_5 = $flag;
		} elsif ($option=~ /REGION_6/ig){
			$REGION_6 = $flag;
		} elsif ($option=~ /REGION_7/ig){
			$REGION_7 = $flag;
		} elsif ($option=~ /REGION_8/ig){
			$REGION_8 = $flag;
		} elsif ($option=~ /REGION_9/ig){
			$REGION_9 = $flag;
		} elsif ($option=~ /REGION_0/ig){
			$REGION_10 = $flag;
		} elsif ($option=~ /EASYSERVER/ig){
			$SERVER = $flag;
		} elsif ($option=~ /UPLOAD/ig){
			$UPLOAD = $flag;
		} elsif ($option=~ /WORKTYPE/ig){
			$WORKTYPE = $flag;
		};    
		  	  
	}; # foreach $line (@config){}

	%config_hash = (
		
		'url' 			=>	$URL,
		'pdepth'		=>	$DEPTH_Path,
		'ldepth'		=>	$DEPTH_Link,
		'pages'			=>	$CRAWLPAGES,
		'elinks'		=>	$FOLLOW_EXTERN_LINKS,
		'slocal'		=>	$STORE_Local,
		'spath'			=>	$STORE_Path,
		'description'	=>	$DESC,
		'keywords'		=>	$KEYW,
		'title'			=>	$TITLE,
		'date'			=>	$DATE,
		'body'			=>	$BODY,
		'debug'			=>	$DEBUG,
		'output'		=>	$OUTPUT,
		'language'		=>	$LANG,	
		'os'			=>	$OS,
		'tmppath'		=>	$TMP,
		'rar'			=>  $RAR,
		'unrar'			=>  $UNRAR,
		'scanlist'		=>	$SCANLIST,
		'region_1'		=>  $REGION_1,
		'region_2'		=>  $REGION_2,
		'region_3'		=>  $REGION_3,
		'region_4'		=>  $REGION_4,
		'region_5'		=>  $REGION_5,
		'region_6'		=>  $REGION_6,
		'region_7'		=>  $REGION_7,
		'region_8'		=>  $REGION_8,
		'region_9'		=>  $REGION_9,
		'region_10'		=>  $REGION_10,
		'server'		=>  $SERVER,
		'upload'		=>  $UPLOAD,
		'worktype'		=>  $WORKTYPE,
		);

	return %config_hash;
	
}; # sub read_easyspider_client_config() {}
################## Subroutinen zum Auslesen der Configuration: Ende

############### Subroutinen für Rückgabe der Configuration: Start

# gibt pfadtiefe zurück
sub cfg_pdepth {
	return %config->{"pdepth"};
};

# gibt linktiefe zurück
sub cfg_ldepth {
	return %config->{"ldepth"};
};

# gibt anzahl zu crawlender seiten zurück
sub cfg_pages {
	return %config->{"pages"};
};

# gibt pfadtiefe zurück
sub cfg_followlinks {
	return %config->{"elinks"};
};

# gibt zurück, ob lokal gespeichert werden soll
sub cfg_storelocal {
	return %config->{"slocal"};
};

# gibt pfad zum speichern der seiten zurück
sub cfg_storepath {
	return %config->{"spath"};
};

# gibt support für XXX zurück
sub cfg_description {
	return %config->{"description"};
};

# gibt support für XXX zurück
sub cfg_keywords {
	return %config->{"keywords"};
};

# gibt support für XXX zurück
sub cfg_title {
	return %config->{"title"};
};

# gibt support für XXX zurück
sub cfg_date {
	return %config->{"date"};
};

# gibt support für XXX zurück
sub cfg_body {
	return %config->{"body"};
};

# gibt support für XXX zurück
sub cfg_debug {
	return %config->{"debug"};
};

sub cfg_output {
	return %config->{"output"};
};

sub cfg_lang {
	return %config->{"language"};
};

sub cfg_os {
	return %config->{"os"};
};

sub cfg_tmp {
	return %config->{"tmppath"};
};

sub cfg_rar {
	return %config->{"rar"};
};

sub cfg_unrar {
	return %config->{"unrar"};
};

sub cfg_scanlist {
	return %config->{"scanlist"};
};

sub cfg_region_1 {
	return %config->{"region_1"};
};

sub cfg_region_2 {
	return %config->{"region_2"};
};

sub cfg_region_3 {
	return %config->{"region_3"};
};

sub cfg_region_4 {
	return %config->{"region_4"};
};

sub cfg_region_5 {
	return %config->{"region_5"};
};

sub cfg_region_6 {
	return %config->{"region_6"};
};

sub cfg_region_7 {
	return %config->{"region_7"};
};

sub cfg_region_8 {
	return %config->{"region_8"};
};

sub cfg_region_9 {
	return %config->{"region_9"};
};

sub cfg_region_10 {
	return %config->{"region_10"};
};

sub cfg_server {
	return %config->{"server"};
};

sub cfg_upload {
	return %config->{"upload"};
};

sub cfg_worktype {
	return %config->{"worktype"};
};

################## Subroutinen für Rückgabe der Configuration: Ende


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