#!/usr/bin/perl

package Session::PHP;
$VERSION = '1.0';

require Exporter;
use MD5;

@ISA = 'Exporter';
@EXPORT_OK = qw( new init SID get put);
@EXPORT = qw( new init SID get put );


########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class) = @_;
	my $object = bless {}, $class;
	return ($object);

};  # sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende


sub get(){
	
	my ($self, $path, $sid) = @_;
	
	if ( $^O =~ /win/i ) {
		$SID_PATH = "$path\\$sid";
	} else {
		$SID_PATH = "/tmp/$sid";
	}; 

	open(READ, "<$SID_PATH");
	while ( $line = <READ> ) {
		my (undef, $key, undef, $value) = split('\'',  $line);
		%HASH->{$key} = $value;
	};
	close READ;
	return \%HASH;

};

sub del() {

	my ($self, $path, $sid) = @_;
	
	if ( $^O =~ /win/i ) {
		$SID_PATH = "$path\\$sid";
		if ( !unlink $SID_PATH ) {
			system("del /F $SID_PATH");
		};
	} else {
		$SID_PATH = "/tmp/$sid";
		if ( !unlink $SID_PATH ) {
			system("rm -rf $SID_PATH");
		};
	};
	
	return 1;

};


sub put(){
	
	my ($self, $hashref, $path, $sid) = @_;
	my %HASH = %$hashref;

	if ( $^O =~ /win/i ) {
		$SID_PATH = "$path\\$sid";
	} else {
		$SID_PATH = "/tmp/$sid";
	}; 

	open(WRITE, ">$SID_PATH");

	while ( my ($key, $value) = each(%HASH) ) {
		print WRITE "'$key' ####### '$value'\n";
	};
	close WRITE;

	return 1;

};


sub init() {
	
	my ($self) = @_;
	my $SID_PATH;

	if ( $^O =~ /win/i ) {
		$SID_PATH = "C:\\temp";
		if ( !mkdir($SID_PATH, 0755)) {
			#my $stat = `mkdir $SID_PATH`;
		};
	} else {
		$SID_PATH = "/tmp";
		if ( !mkdir($SID_PATH, 0755)) {
			#my $stat = `mkdir $SID_PATH`;
		};
	}; 

	return $SID_PATH; 

};


sub SID() {

	my ($self)	= @_;
	my $s_time	= time;
	my $RAND	= int(rand(99999999999999999999999))+1;
	select(undef, undef, undef, 0.2452);
	my $c_time	= localtime;
	my $RAW		= "#$$#$s_time#$^P#$RAND#$^O#$)#$^F#$self#$^T#$^X#$^H#$>#$c_time#$0#";
	my $SID_OBJ = MD5->new();
	$SID_OBJ->add($RAW);
	return $SID_OBJ->hexdigest();

};

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