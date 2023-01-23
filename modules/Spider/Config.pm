#!/usr/bin/perl

package Spider::Config;
$VERSION = '1.98';

########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class, $config) = @_;
	our %config = &read_easyspider_client_config($config);
	my $object = bless {}, $class;
	return $object;

}; #sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende


############### Subroutinen für Rückgabe der Configuration: Start
# gibt url zum scannen zurück	
sub cfg_url() {
	return %config->{"url"};
};

# gibt pfadtiefe zurück
sub cfg_pdepth() {
	return %config->{"pdepth"};
};

# gibt linktiefe zurück
sub cfg_ldepth() {
	return %config->{"ldepth"};
};

# gibt anzahl zu crawlender seiten zurück
sub cfg_pages() {
	return %config->{"pages"};
};

# gibt pfadtiefe zurück
sub cfg_followlinks() {
	return %config->{"elinks"};
};

# gibt zurück, ob lokal gespeichert werden soll
sub cfg_storelocal() {
	return %config->{"slocal"};
};

# gibt pfad zum speichern der seiten zurück
sub cfg_storepath() {
	return %config->{"spath"};
};

# gibt support für XXX zurück
sub cfg_description() {
	return %config->{"description"};
};

# gibt support für XXX zurück
sub cfg_keywords() {
	return %config->{"keywords"};
};

# gibt support für XXX zurück
sub cfg_title() {
	return %config->{"title"};
};

# gibt support für XXX zurück
sub cfg_date() {
	return %config->{"date"};
};

# gibt support für XXX zurück
sub cfg_body() {
	return %config->{"body"};
};

# gibt support für XXX zurück
sub cfg_debug() {
	return %config->{"debug"};
};

sub cfg_output() {
	return %config->{"output"};
};

sub cfg_lang() {
	return %config->{"language"};
};

sub cfg_os() {
	return %config->{"os"};
};

sub cfg_tmp() {
	return %config->{"tmppath"};
};

sub cfg_pdfconverter() {
	return %config->{"pdfconvert"};
};

sub cfg_rar() {
	return %config->{"rar"};
};

sub cfg_unrar() {
	return %config->{"unrar"};
};

sub cfg_docconverter {
	return %config->{"docconvert"};
};

sub cfg_pptconverter() {
	return %config->{"pptconvert"};
};

sub cfg_xlsconverter() {
	return %config->{"xlsconvert"};
};

sub cfg_rtfconverter {
	return %config->{"rtfconvert"};
};

sub cfg_region_1() {
	return %config->{"region_1"};
};

sub cfg_region_2() {
	return %config->{"region_2"};
};

sub cfg_region_3() {
	return %config->{"region_3"};
};

sub cfg_region_4() {
	return %config->{"region_4"};
};

sub cfg_region_5() {
	return %config->{"region_5"};
};

sub cfg_region_6() {
	return %config->{"region_6"};
};

sub cfg_region_7() {
	return %config->{"region_7"};
};

sub cfg_region_8() {
	return %config->{"region_8"};
};

sub cfg_region_9() {
	return %config->{"region_9"};
};

sub cfg_region_10() {
	return %config->{"region_10"};
};

sub cfg_server() {
	return %config->{"server"};
};

sub cfg_template_txt() {
	return %config->{"template_txt"};
};

sub cfg_template_sql() {
	return %config->{"template_sql"};
};

sub cfg_template_xml() {
	return %config->{"template_xml"};
};

sub cfg_template_gew() {
	return %config->{"template_gew"};
};

sub cfg_timeout()	{
	return %config->{"timeout"};
};

sub cfg_useragent()	{
	return %config->{"useragent"};
};

sub cfg_worktype() {
	return %config->{"worktype"};
};

sub cfg_upload() {
	return %config->{"upload"};
};

sub cfg_robots() {
	return %config->{"robots"};
};

sub cfg_useproxy() {
	return %config->{"useproxy"};
};

sub cfg_proxyurl() {
	return %config->{"proxyurl"};
};

sub cfg_proxyuser() {
	return %config->{"proxyuser"};
};

sub cfg_proxypass() {
	return %config->{"proxypass"};
};

################## Subroutinen für Rückgabe der Configuration: Ende


################## Subroutinen zum Auslesen der Configuration: Start
# Aufgabe: &read_easyspider_client_config - lese config in speicher und gib config hash zurück
# Rückgabe: %config_hash mit gespeicherten konfigurationsoptionen

sub read_easyspider_client_config() {

	my $config = @_[0];
	
	open(CONFIG, "<$config") or die "Easypider.pm: &read_easyspider_client_config(): Cannot read config file \'$cfg\': $!\n";
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
			
		if ($option =~ /STARTURL/ig){
			$URL = $flag;
		} elsif ($option =~ /PATHDEPTH/ig){
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
		} elsif ($option =~ /PDFTOHTML/ig) {
			$PDFCONVERT = $flag;
		} elsif ($option =~ /DOCTOTXT/ig) {
			$DOCCONVERT = $flag;	
		} elsif ($option =~ /XLSTOHTML/ig) {
			$XLSCONVERT = $flag;	
		} elsif ($option =~ /PPTTOHTML/ig) {
			$PPTCONVERT = $flag;	
		} elsif ($option =~ /RTFTOHTML/ig) {
			$RTFCONVERT = $flag;	
		} elsif ($option=~ /REGION_1/ig){
			$REGION_1 = $flag;
		} elsif ($option=~ /REGION_2/ig){
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
		} elsif ($option=~ /TIMEOUT/ig){
			$TIMEOUT = $flag;
		} elsif ($option=~ /USERAGENT/ig){
			$UA = $temp_flag;		# richtig so!!!
		} elsif ($option=~ /WORKTYPE/ig){
			$WORKTYPE = $flag;
		} elsif ($option=~ /USEROBOTSTXT/ig){
			$ROBOTS = $flag;
		} elsif ($option=~ /USEPROXY/ig){
			$USEPROXY = $flag;
		} elsif ($option=~ /PROXYURL/ig){
			$PROXYURL = $flag;
		} elsif ($option=~ /PROXYUSER/ig){
			$PROXYUSER = $flag;
		} elsif ($option=~ /PROXYPASS/ig){
			$PROXYPASS = $flag;
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
		'pdfconvert'	=>	$PDFCONVERT,
		'docconvert'	=>	$DOCCONVERT,
		'pptconvert'	=>	$PPTCONVERT,
		'xlsconvert'	=>	$XLSCONVERT,
		'rtfconvert'	=>	$RTFCONVERT,
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
		'timeout'		=>  $TIMEOUT,
		'useragent'		=>  $UA,
		'worktype'		=>  $WORKTYPE,
		'robots'		=>  $ROBOTS,
		'useproxy'		=>  $USEPROXY,
		'proxyurl'		=>  $PROXYURL,
		'proxyuser'		=>  $PROXYUSER,
		'proxypass'		=>  $PROXYPASS,
		#''		=>  ,
		);

		return %config_hash;
	
}; # sub read_easyspider_client_config() {}
################## Subroutinen zum Auslesen der Configuration: Ende

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