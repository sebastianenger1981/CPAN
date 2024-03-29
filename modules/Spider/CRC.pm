#!/usr/bin/perl

package Spider::CRC;
$VERSION = '1.2';

require Exporter;
use MD5;

@ISA = 'Exporter';
@EXPORT_OK = qw( CRCfromFile );
@EXPORT = qw( CRCfromFile );


########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# R�ckgabe: $object

sub new() {
	
	my ($class) = @_;
	my $object = bless {}, $class;
	return ($object);

};  # sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende

################## Subroutinen zum Erstellen von CRC Pr�fsummen f�r die �bergebenen Datei : Start
# Aufgabe: &CRCfromFile() - erstelle CRC f�r FILE-Filehandle
# R�ckgabe: Hexwert des berechneten CRC Wertes

sub CRCfromFile(){
	
	my ($self, $filepath) = @_;
	my $CRC = MD5->new();
	
	open(FILE, "<$filepath") or logmsg("CRC.log", "Spider::CRC:logmsg(): unable to stat: '$filepath' / ERRORMSG : '$!' !\n");
		$CRC->addfile(FILE);
	close FILE;
	
	return $CRC->hexdigest();

}; # sub CRCfromFile(){ }
################## Subroutinen zum Erstellen von CRC Pr�fsummen f�r die �bergebenen Datei : Ende


sub CRCfromString(){
	return 1;
};

################## Subroutinen zum loggen von nachrichten : Start
# Aufgabe: &logmsg() - protokolliere nachricht
# R�ckgabe: nichts

sub logmsg(){

	my ($file, $msg ) = @_;
	
	open(WH,">>$file") or warn "Spider::CRC:logmsg(): unable to stat: '$file' / ERRORMSG : '$!' / [". localtime() . "] LOGMSG: '$msg' !\n";
		print WH "[". localtime() . "] $msg";
	close WH;

}; # sub logmsg(){}
################## Subroutinen zum loggen von nachrichten :	Ende

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