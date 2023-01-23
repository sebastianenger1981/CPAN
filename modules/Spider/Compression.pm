#!/usr/bin/perl

package Spider::Compression;
$VERSION = '1.2';


########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class) = @_;
	my $object = bless {}, $class;
	return $object;

};  #sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende


# rar.exe a -y -cl -inul -m5  ziel.tar C:\target
sub rar() {
	
	my ($self, $RAR_CONFIG_HASHREF) = @_;
	my $TMPFILE;

	%RAR_CONFIG = %{$RAR_CONFIG_HASHREF};

	my $DIRTOCOMP	= %RAR_CONFIG->{"DIRTOCOMP"};
	my $TMPPATH		= %RAR_CONFIG->{"TMPPATH"};
	my $RAR_EXEC	= %RAR_CONFIG->{"RAR_EXEC"};
	my $FILENAME	= %RAR_CONFIG->{"FILENAME"};
	my $SPEED		= %RAR_CONFIG->{"SPEED"};
	my $OS			= %RAR_CONFIG->{"OS"};

	#chomp($TMPPATH,$FILENAME,$SPEED, $OS,$DIRTOCOMP,$RAR_EXEC);

	# optimized for speed: -m1
	# optimized for transport: -m5

	if ( lc( $OS ) eq "linux" ) {
		$TMPFILE  = "$TMPPATH/$FILENAME";
	} elsif ( lc( $OS ) eq "windows" ) {
		$TMPFILE  = "$TMPPATH\\$FILENAME";
	};

	my $TMP = `$RAR_EXEC a -y -cl -inul -m$SPEED $TMPFILE $DIRTOCOMP`;
	return $TMPFILE;

}; # sub rar() {}


sub unrar(){

	my ($self, $RAR_CONFIG_HASHREF) = @_;
	my $TMPFILE;

	%RAR_CONFIG = %{$RAR_CONFIG_HASHREF};

	my $RARFILE		= %RAR_CONFIG->{"RARFILE"};
	my $STOREPATH	= %RAR_CONFIG->{"STOREPATH"};
	my $UNRAR_EXEC	= %RAR_CONFIG->{"UNRAR"};
	my $FILENAME	= %RAR_CONFIG->{"FILENAME"};
	my $OS			= %RAR_CONFIG->{"OS"};
	my $TMPPATH;

	$FILENAME =~ s/\.rar//gi;

	if ( lc( $OS ) eq "linux" ) {
		$TMPPATH  = "$STOREPATH/$FILENAME";
		if ( !mkdir($TMPPATH, 0755) ) {
			system("mkdir $TMPPATH");
			system("mk $TMPPATH");
		};
	} elsif ( lc( $OS ) eq "windows" ) {
		$TMPPATH  = "$STOREPATH\\$FILENAME";
		if ( !mkdir($TMPPATH, 0755) ) {
			system("mkdir $TMPPATH");
			system("mk $TMPPATH");
		};
	};
	
	my $TMP = `$UNRAR_EXEC x -y -cl -o+ $RARFILE $TMPPATH`;
	return $TMPPATH; 

}; # sub unrar() {}


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