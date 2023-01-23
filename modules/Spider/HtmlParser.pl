#!/usr/bin/perl

require Exporter;

@ISA = 'Exporter';
$VERSION = "1.3";
@EXPORT_OK = qw( HtmlParser as_string);
@EXPORT = qw(HtmlParser as_string);


sub HtmlParser(){

	my $REF = shift;	  # erwarte array referenz
	my $content, $line, $ARRAYREF, $TEXT, @array;

	if ($REF =~ /^SCALAR/i) {
	   # this is ok !!! - no commands here
	   $content = ${$REF};
	} elsif ($REF =~ /^ARRAY/i) {
		$content = &as_string($REF);
	} elsif ($REF =~ /^HASH/i) {
		die "HtmlParser(): Hash REF\n";
	};
	
	$content =~ s/<!--(.*?)-->//igms;					# remove comments
	$content =~ s/<script.*?>(.*?)<\/script>//igsm;		# remove scripts
	# $content =~ s/<a.*?>(.*?)<\/a>//igsm;				# remove links	-> rauslassen -> es entfernt zuviel informationen
	$content =~ s/<select.*?>(.*?)<\/select>//igsm;		# remove selects
	$content =~ s/<style.*?>(.*?)<\/style>//igsm;		# remove style
	$content =~ s/<.*?>//igms;							# remove html tags
	$content = &html_codes_to_ascii($content);
	
	#
	#### Algorithmus zum umwandeln des Inhaltes des Strings $content in formatierten Text, Zeilenumbrüche bei . ! ?
	#
	
	my @array = split(' ', $content);

	foreach $line (@array) {
		
		if ($line =~ /^\d{1,2}\.\d{1,2}\.\d{2,4}/) {	# if line contains date, just do no manipulation	
		} elsif ($line =~ /^\w{1,}\.\w{1,}/i) {			# if line contains "Blah.Blah",just do no manipulation	
		} elsif ($line =~ /\!/) {						# substitue " BLAH BLAH BLA !" with " BLAH BLAH BLA !\n"
			$line =~ s/\!{1,}/\!\n/; 
	   	} elsif ($line =~ /\?/) {
			$line =~ s/\?{1,}/\?\n/; 
		} elsif ($line =~ /\?/) {
			$line =~ s/\?\s{1,}/\?\s{1,}\n/; 
		} elsif ($line =~ /\@/) {						# enthält email
		} else {										# normal line, just add it to array
		};
	};

	my @array = join(" ", @array);
	$ARRAYREF = \@array;
	$TEXT = &as_string($ARRAYREF);
	undef @array, @content;

	return $TEXT;

};


# wandle array in scalar um
sub as_string {

	my $REF = shift;
	my $html_one_line, $content;

	foreach $content (@{$REF}) {
		$html_one_line = $html_one_line . $content;
	};

	return $html_one_line;

}; # sub slurp_from_array_into_scalar() {}
################################################


############# Subroutine zum Umwandeln von HTML nach ascii Text: Start
# Aufgabe: & pdf_to_txt - wandle html zu text um 
# Rückgabe: @content mit text

sub html_codes_to_ascii() {

	my ($HTML) = @_;
	my(@HTMLPage, $SymbLine, $ascii, $html);

	$HTML =~ s/&nbsp;/ /g;
	$HTML =~ s/\s/ /g;
	$HTML =~ s/\s\s*/ /g;
	$HTML =~ s/\n\s*\n\s*/\n\n/g;
	$HTML =~ s/\n */\n/g;
	
	foreach $SymbLine (&HTMLSymb) {
		($ascii, $html) = split(/\s\s*/,$SymbLine);
		$HTML =~ s/$html/$ascii/g;
		$HTML =~ s/'//g;
		$HTML =~ s/`//g;
		$HTML =~ s/&#180;//;
	};
	
	return($HTML);
	
	# HTML Codes
	sub HTMLSymb() {
		return (
		". &middot;",
		"&	&amp;",
		"\"	&quot;",
		"<	&lt;",
		">	&gt;",
		"©	&copy;",
		"®	&reg;",
		"Æ	&AElig;",
		"Á	&Aacute;",
		"Â	&Acirc;",
		"À	&Agrave;",
		"Å	&Aring;",
		"Ã	&Atilde;",
		"Ä	&Auml;",
		"Ç	&Ccedil;",
		"Ð	&ETH;",
		"É	&Eacute;",
		"Ê	&Ecirc;",
		"È	&Egrave;",
		"Ë	&Euml;",
		"Í	&Iacute;",
		"Î	&Icirc;",
		"Ì	&Igrave;",
		"Ï	&Iuml;",
		"Ñ	&Ntilde;",
		"Ó	&Oacute;",
		"Ô	&Ocirc;",
		"Ò	&Ograve;",
		"Ø	&Oslash;",
		"Õ	&Otilde;",
		"Ö	&Ouml;",
		"Þ	&THORN;",
		"Ú	&Uacute;",
		"Û	&Ucirc;",
		"Ù	&Ugrave;",
		"Ü	&Uuml;",
		"Ý	&Yacute;",
		"á	&aacute;",
		"â	&acirc;",
		"æ	&aelig;",
		"à	&agrave;",
		"å	&aring;",
		"ã	&atilde;",
		"ä	&auml;",
		"ç	&ccedil;",
		"é	&eacute;",
		"ê	&ecirc;",
		"è	&egrave;",
		"ð	&eth;",
		"ë	&euml;",
		"í	&iacute;",
		"î	&icirc;",
		"ì	&igrave;",
		"ï	&iuml;",
		"ñ	&ntilde;",
		"ó	&oacute;",
		"ô	&ocirc;",
		"ò	&ograve;",
		"ø	&oslash;",
		"õ	&otilde;",
		"ö	&ouml;",
		"ß	&szlig;",
		"þ	&thorn;",
		"ú	&uacute;",
		"û	&ucirc;",
		"ù	&ugrave;",
		"ü	&uuml;",
		"ý	&yacute;",
		"ÿ	&yuml;",
		" 	&#160;",
		"¡	&#161;",
		"¢	&#162;",
		"£	&#163;",
		"¥	&#165;",
		"¦	&#166;",
		"§	&#167;",
		"¨	&#168;",
		"©	&#169;",
		"ª	&#170;",
		"«	&#171;",
		"¬	&#172;",
		"­	&#173;",
		"®	&#174;",
		"¯	&#175;",
		"°	&#176;",
		"±	&#177;",
		"²	&#178;",
		"³	&#179;",
		"´	&#180;",
		"µ	&#181;",
		"¶	&#182;",
		"·	&#183;",
		"¸	&#184;",
		"¹	&#185;",
		"º	&#186;",
		"»	&#187;",
		"¼	&#188;",
		"½	&#189;",
		"¾	&#190;",
		"¿	&#191;",
		"×	&#215;",
		"Þ	&#222;",
		"÷	&#247;",
		"   &#94;",
		"ü  &#252;",

		);
		}; # sub HTMLSymb() {}

}; # sub html_to_ascii_parser() {}
########### Soubroutine zum extrahieren von html inforamtionen


###########################################################
#
#	Algorithmus zum Aufteilen des Strings in 120 Zeichen
#
#	foreach $line ( split(//, $content) ){
#		
#		my $c++;
#		
#		if ( ($c >= "120") && ($line =~ ' ') ) {
#			$line =~ s/$line/$line\n/;
#			$c = "0";
#		};
#		
#		push(@CONTENT, $line);
#
#	};
#
#	undef $content;
#	
#	$ARRAYREF = \@CONTENT;
#	$content = &array_to_scalar($ARRAYREF);
#
###########################################################

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