#!/usr/bin/perl

package Spider::Parser;
$VERSION = '1.5';

require "Spider\\HtmlParser.pl";
use LWP::Simple;

########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class) = @_;
	my $object = bless {}, $class;
	return ($object);

};  # sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende

############# Subroutine zum Umwandeln von xml nach ascii Text: Start
# Aufgabe: ParseXML - wandle xml zu text um
# Rückgabe: $text

sub ParseXML() {

	my $self	= shift;
	my $file	= shift;
	my @all		= split(/<.*?>(.*?)<\/.*?>/, $file);
	my $text;

	foreach my $content ( @all ) {
		next if ( $content !~ /(\w)/ );
		next if ( $content =~ /<.*?>/ );
		next if ( $content =~ /<\/.*?>/ );
		$text = $text . "$content\n";
	};

	return $text;

}; # sub ParseXML() {}
############# Subroutine zum Umwandeln von xml nach ascii Text: Ende

############# Subroutine zum Umwandeln von rss nach ascii Text: Start
# Aufgabe: ParseRSS - wandle rss zu text um mit hilfe programme
# Rückgabe: $text

sub ParseRSS(){

	my $self	= shift;
	my $xml		= shift;

	my $text;
	
	use XML::RSS::Parser::Lite;
	my $rp = new XML::RSS::Parser::Lite;
	$rp->parse($xml);
	
	for (my $i = 0; $i < $rp->count(); $i++) {
			my $it = $rp->get($i);
			$text = $text . $it->get('title') . "\n " . $it->get('url') . "\n " . $it->get('description') . " \n";
	};

	&logmsg("parser.log", "Spider::Parser::ParseRSS() - Parsing Content !\n");

	return $text;
}; # sub ParseRSS(){}
############# Subroutine zum Umwandeln von rss nach ascii Text: Ende


############# Subroutine zum Umwandeln von rtf nach ascii Text: Start
# Aufgabe: & rtf_to_txt - wandle xls zu text um mit hilfe externer programme
# Rückgabe: @content mit text

sub ParseRTF {

	my $self			= shift;
	my $CONFIG_HASHREF	= shift;
	my $url				= shift;
	my %CONFIG			= %{$CONFIG_HASHREF};

	my $tmp_file, $ARRAYREF, $text, @content;
	my $int = int(rand(100000) + 1);

	my $OS			= %CONFIG->{"OS"};
	my $rtf_convert = %CONFIG->{"RTF_CONVERT"};
	my $tmp_path	= %CONFIG->{"TMPPATH"};

	&logmsg("parser.log", "Spider::Parser::ParseRTF() - Parsing Url '$url' !\n");

	if ( lc( $OS ) eq "linux" ) {
		$tmp_file  = "$tmp_path/rtftemp_$int.rtf";
	} elsif ( lc( $OS ) eq "windows" ) {
		$tmp_file  = "$tmp_path\\rtftemp_$int.rtf";
	};

	getstore($url, $tmp_file); 
	
	open(README, "$rtf_convert $tmp_file |") or &logmsg("parser.log", "Spider::Parser::ParseRTF() - cannot open pipe to program '$rtf_convert' !\n");
		@content = <README>;
	close(README);
	
	$ARRAYREF	= \@content; 
   	$text		= &HtmlParser($ARRAYREF);

	unlink $tmp_file;
	return $text;

}; # sub ParseRTF() {}
############# Subroutine zum Umwandeln von RTF nach ascii Text: Ende


############# Subroutine zum Umwandeln von Excel nach ascii Text: Start
# Aufgabe: & pdf_to_txt - wandle xls zu text um mit hilfe externer programme
# Rückgabe: @content mit text

sub ParseXLS {

	my $self			= shift;
	my $CONFIG_HASHREF	= shift;
	my $url				= shift;
	my %CONFIG			= %{$CONFIG_HASHREF};

	my $tmp_file, $ARRAYREF,$text, @content;
	my $int = int(rand(100000) + 1);

	my $OS			= %CONFIG->{"OS"};
	my $xls_convert = %CONFIG->{"XLS_CONVERT"};
	my $tmp_path	= %CONFIG->{"TMPPATH"};

	&logmsg("parser.log", "Spider::Parser::ParseXLS() - Parsing Url '$url' !\n");

	if ( lc( $OS ) eq "linux" ) {
		$tmp_file  = "$tmp_path/xlstemp_$int.xls";
	} elsif ( lc( $OS ) eq "windows" ) {
		$tmp_file  = "$tmp_path\\xlstemp_$int.xls";
	};

	getstore($url, $tmp_file);

	# open(README, "$converter -a -te $tmp_file |") - für entfernung alle unnötigen leerzeichen, aber dann steht der text alles in einer zeile
	open(README, "$xls_convert $tmp_file |") or &logmsg("parser.log", "Spider::Parser::ParseXLS() - cannot open pipe to program '$xls_convert' !\n");
		@content = <README>;
	close(README);
	
	$ARRAYREF	= \@content; 
   	$text		= &HtmlParser($ARRAYREF);

	unlink $tmp_file;
	return $text;

}; # sub ParseXLS() {}
############# Subroutine zum Umwandeln von Excel nach ascii Text: Ende


############# Subroutine zum Umwandeln von Powerpoints nach ascii Text: Start
# Aufgabe: & pdf_to_txt - wandle ppt zu text um mit hilfe externer programme
# Rückgabe: @content mit text

sub ParsePPT {

	my $self			= shift;
	my $CONFIG_HASHREF	= shift;
	my $url				= shift;
	my %CONFIG			= %{$CONFIG_HASHREF};

	my $tmp_file, $ARRAYREF,$text, @content;
	my $int = int(rand(100000) + 1);

	my $OS			= %CONFIG->{"OS"};
	my $ppt_convert = %CONFIG->{"PPT_CONVERT"};
	my $tmp_path	= %CONFIG->{"TMPPATH"};

	&logmsg("parser.log", "Spider::Parser::ParsePPT() - Parsing Url '$url' !\n");

	if ( lc( $OS ) eq "linux"  ) {
		$tmp_file  = "$tmp_path/ppttemp_$int.ppt";
	} elsif ( lc( $OS ) eq "windows"  ) {
		$tmp_file  = "$tmp_path\\ppttemp_$int.ppt";
	};

	getstore($url, $tmp_file);

	open(README, "$ppt_convert $tmp_file |") or &logmsg("parser.log", "Spider::Parser::ParsePPT() - cannot open pipe to program '$ppt_convert' !\n");
		@content = <README>;
	close(README);
	
	$ARRAYREF	= \@content; 
   	$text		= &HtmlParser($ARRAYREF);
	
	unlink $tmp_file;
	return $text;

}; # sub ParsePPT() {}
############# Subroutine zum Umwandeln von Powerpoints nach ascii Text: Ende


############# Subroutine zum Umwandeln von PDFs nach ascii Text: Start
# Aufgabe: & pdf_to_txt - wandle pdf zu text um mit hilfe externer programme
# Rückgabe: @content mit text

sub ParsePDF {

	my $self			= shift;
	my $CONFIG_HASHREF	= shift;
	my $url				= shift;
	my %CONFIG			= %{$CONFIG_HASHREF};

	my $tmp_file, $ARRAYREF, @content, @file, $file, $text;
	my $int = int(rand(100000) + 1);

	my $OS			= %CONFIG->{"OS"};
	my $pdf_convert = %CONFIG->{"PDF_CONVERT"};
	my $tmp_path	= %CONFIG->{"TMPPATH"};

	&logmsg("parser.log", "Spider::Parser::ParsePDF() - Parsing Url '$url' !\n");
		
	if ( lc( $OS ) eq "linux" ) {
		$tmp_file  = "$tmp_path/pdftemp_$int.pdf";
	} elsif ( lc( $OS ) eq "windows"  ) {
		$tmp_file  = "$tmp_path\\pdftemp_$int.pdf";
	};

	getstore($url, $tmp_file);
	
	open(README, "$pdf_convert $tmp_file |") or &logmsg("parser.log", "Spider::Parser::ParsePDF() - cannot open pipe to program '$pdf_convert' !\n");
		@content = <README>;
	close(README);

	@file = split('\.', $tmp_file);
	$file = @file[0] . "s.html";
	
	open(RH,"<$file") or &logmsg("parser.log", "Spider::Parser::ParsePDF() - cannot open File '$file' : $!\n");
		@content = <RH>;
	close RH;
		
	$ARRAYREF	= \@content; 
   	$text		= &HtmlParser($ARRAYREF);
	
	unlink $tmp_file;
	return $text;

}; # sub ParsePDF() {}
############# Subroutine zum Umwandeln von PDFs nach ascii Text: Ende


############# Subroutine zum Umwandeln von Docss nach ascii Text: Start
# Aufgabe: &parseDOC - wandle doc zu text um mit hilfe externer programme
# Rückgabe: @content mit text

sub ParseDOC {

	my $self			= shift;
	my $CONFIG_HASHREF	= shift;
	my $url				= shift;
	my %CONFIG			= %{$CONFIG_HASHREF};
	
	my $tmp_file, $ARRAYREF;
	my $int = int(rand(100000) + 1);
	
	my $OS			= %CONFIG->{"OS"};
	my $doc_convert = %CONFIG->{"DOC_CONVERT"};
	my $tmp_path	= %CONFIG->{"TMPPATH"};

	&logmsg("parser.log", "Spider::Parser::ParseDOC() - Parsing Url '$url' !\n");

	if ( lc( $OS ) eq "linux" ) {
		$tmp_file  = "$tmp_path/doctemp_$int.doc";
	} elsif ( lc( $OS ) eq "windows" ) {
		$tmp_file  = "$tmp_path\\doctemp_$int.doc";	# todo: bei windows eventuell '\\' als trennzeichen nötig?
	};
	
	getstore($url, $tmp_file);
	
	open(DOC, "$doc_convert $tmp_file |") or &logmsg("parser.log", "Spider::Parser::ParseDOC() - cannot open pipe to program '$doc_convert' !\n");
		@content = <DOC>;
	close DOC;

	$ARRAYREF	= \@content; 
   	$text		= &HtmlParser($ARRAYREF);

	unlink $tmp_file;
	return $text;
	
}; # sub ParseDOC {}
############# Subroutine zum Umwandeln von PDFs nach ascii Text: Ende


################## Subroutinen zum loggen von nachrichten : Start
# Aufgabe: &logmsg() - protokolliere nachricht
# Rückgabe: nichts

sub logmsg(){

	my ($file, $msg ) = @_;
	
	open(WH,">>$file") or warn "Spider::Parser::logmsg(): unable to stat: '$file' / ERRORMSG : '$!' / [". localtime() . "] LOGMSG: '$msg' !\n";
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