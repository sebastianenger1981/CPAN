#!/usr/bin/perl

package Spider::ResultParser;

use XML::Writer;
use IO::File;

$VERSION = '2.0';

########### Subroutine zur Erstellung eines neuen Objektes:  Start
# Aufgabe: new() - neues Objekt erstellen
# Rückgabe: $object

sub new() {
	
	my ($class ) = @_;
	my $object = bless {}, $class;
	return $object;

};  #sub new() { } 
########### Subroutine zur Erstellung eines neuen Objektes:  Ende

########### Subroutine zur Erstellung der Output Datei in xml:  Start
# Aufgabe: FormatXMLComplex() - neue xml Datei erstellen
# Rückgabe: "done"

sub FormatXMLComplex(){
	
	my $self			= shift;
	my $path			= shift;
	my $OS				= shift;
	my $resulthashref	= shift;
	my $HOSTNAME		= shift;
	my $BODY			= shift;
	my %INFO			= %{$resulthashref};
	
	my $URL				= %INFO->{'URL'};
	my $LINKDEPTH		= %INFO->{'LINKDEPTH'};
	my $LINKCOUNT		= %INFO->{'LINKCOUNT'};
	my $SPIDERDATE		= %INFO->{'SPIDER-DATE'};
	my $FILETYPE		= %INFO->{'FILETYPE'};
	my $CONTENTTYPES	= %INFO->{'CONTENTTYPE'};
	my $METAKEYS		= %INFO->{'META-KEYS'};
	my $CONTENTTYPE		= %INFO->{'META-CONTENT'};
	my $PRAGMA			= %INFO->{'META-PRAGMA'};
	my $REVISIT			= %INFO->{'META-REVISIT'};
	my $DESC			= %INFO->{'META-DESCRIPTION'};
	my $AUTHOR			= %INFO->{'META-AUTHOR'};
	my $DATE			= %INFO->{'META-DATE'};
	my $PUBLISHED		= %INFO->{'META-PUBKLISHED'};
	my $CONTACT			= %INFO->{'META-CONTACT'};
	my $TITLE			= %INFO->{'TITLE'};
	my $REGION1TAG		= %INFO->{'REGION1TAG'};
	my $REGION2TAG		= %INFO->{'REGION2TAG'};
	my $REGION3TAG		= %INFO->{'REGION3TAG'};
	my $REGION4TAG		= %INFO->{'REGION4TAG'};
	my $REGION5TAG		= %INFO->{'REGION5TAG'};
	my $REGION6TAG		= %INFO->{'REGION6TAG'};
	my $REGION7TAG		= %INFO->{'REGION7TAG'};
	my $REGION8TAG		= %INFO->{'REGION8TAG'};
	my $REGION9TAG		= %INFO->{'REGION9TAG'};
	my $REGION10TAG		= %INFO->{'REGION10TAG'};
	my $REGION1CONTENT	= %INFO->{'REGION1'};
	my $REGION2CONTENT	= %INFO->{'REGION2'};
	my $REGION3CONTENT	= %INFO->{'REGION3'};
	my $REGION4CONTENT	= %INFO->{'REGION4'};
	my $REGION5CONTENT	= %INFO->{'REGION5'};
	my $REGION6CONTENT	= %INFO->{'REGION6'};
	my $REGION7CONTENT	= %INFO->{'REGION7'};
	my $REGION8CONTENT	= %INFO->{'REGION8'};
	my $REGION9CONTENT	= %INFO->{'REGION9'};
	my $REGION10CONTENT = %INFO->{'REGION10'};

	my ($date, $time) = split(' ', %INFO->{'SPIDER-DATE'} );
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
	my $time = "$hour,$min,$sec";

	# root: [$linktiefe][Linkanzahl][$hostname][$date][$time].txt
	my $filename = "[" . %INFO->{'LINKDEPTH'} . "][" . %INFO->{'LINKCOUNT'} . "][$HOSTNAME][$date][$time].xml"; 
	
	if ( lc( $OS ) eq "linux" ){
		$storepath = "$path/$filename";
	} elsif ( lc( $OS ) eq "windows" ){
		$storepath = "$path\\$filename";
	};

	my $output = new IO::File(">$storepath");
	my $writer = new XML::Writer(OUTPUT => $output);

	print $output "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" ?>\n";

	$writer->startTag("page");
		print $output "\n";
		$writer->startTag("hostname");
		$writer->characters($HOSTNAME);
		$writer->endTag("hostname"); 
		print $output "\n";
		$writer->startTag("url");
		$writer->characters($URL);
		$writer->endTag("url"); 
		print $output "\n";
		$writer->startTag("filetype");
		$writer->characters( $FILETYPE );
		$writer->endTag("filetype"); 
		print $output "\n";
		$writer->startTag("contenttype");
		$writer->characters( $CONTENTTYPES );
		$writer->endTag("contenttype"); 
		print $output "\n";
		$writer->startTag("linkdepth");
		$writer->characters( $LINKDEPTH );
		$writer->endTag("linkdepth");
		print $output "\n";
		$writer->startTag("linkcount");
		$writer->characters( $LINKCOUNT );
		$writer->endTag("linkcount");
		print $output "\n";
		$writer->startTag("spider-date");
		$writer->characters( $timestamp );
		$writer->endTag("spider-date");
		print $output "\n";
			$writer->startTag("page_basics");
			print $output "\n";
				$writer->startTag("metakeys");
				print $output "\n";
					$writer->startTag("keywords");
					$writer->characters( $METAKEYS );
					$writer->endTag("keywords");
					print $output "\n";	
					$writer->startTag("content-type");
					$writer->characters( $CONTENTTYPE );
					$writer->endTag("content-type");
					print $output "\n";
					$writer->startTag("pragma");
					$writer->characters( $PRAGMA );
					$writer->endTag("pragma");
					print $output "\n";
					$writer->startTag("revisit-after");
					$writer->characters( $REVISIT	 );
					$writer->endTag("revisit-after");
					print $output "\n";
					$writer->startTag("description");
					$writer->characters( $DESC );
					$writer->endTag("description");
					print $output "\n";
					$writer->startTag("author");
					$writer->characters( $AUTHOR );
					$writer->endTag("author");
					print $output "\n";
					$writer->startTag("date");
					$writer->characters( $DATE );
					$writer->endTag("date");
					print $output "\n";
					$writer->startTag("published");
					$writer->characters( $PUBLISHED );
					$writer->endTag("published");
					print $output "\n";
					$writer->startTag("contact");
					$writer->characters( $CONTACT );
					$writer->endTag("contact");
					print $output "\n";
				$writer->endTag("metakeys");
				print $output "\n";
			$writer->startTag("title");
			$writer->characters( $TITLE );
			$writer->endTag("title");
			print $output "\n";
		$writer->endTag("page_basics");
		print $output "\n";
		$writer->startTag("page_enhanced");
		print $output "\n";
			$writer->startTag("body");
			# $writer->characters( $BODY );
			print $output "$BODY";	# fix 
			$writer->endTag("body");
			print $output "\n";
			$writer->startTag("extern_regions");
				print $output "\n";
				$writer->startTag("region_1_tag",
									"tag" => "$REGION1TAG");
				$writer->characters( $REGION1CONTENT );
				$writer->endTag("region_1_tag");
				print $output "\n";
				$writer->startTag("region_2_tag",
									"tag" => "$REGION2TAG");
				$writer->characters( $REGION2CONTENT );
				$writer->endTag("region_2_tag");
				print $output "\n";
				$writer->startTag("region_3_tag",
									"tag" => "$REGION3TAG");
				$writer->characters( $REGION3CONTENT );
				$writer->endTag("region_3_tag");
				print $output "\n";
				$writer->startTag("region_4_tag",
									"tag" => "$REGION4TAG");
				$writer->characters( $REGION4CONTENT );
				$writer->endTag("region_4_tag");
				print $output "\n";
				$writer->startTag("region_5_tag",
									"tag" => "$REGION5TAG");
				$writer->characters( $REGION5CONTENT );
				$writer->endTag("region_5_tag");
				print $output "\n";
				$writer->startTag("region_6_tag",
									"tag" => "$REGION6TAG");
				$writer->characters( $REGION6CONTENT );
				$writer->endTag("region_6_tag");
				print $output "\n";
				$writer->startTag("region_7_tag",
									"tag" => "$REGION7TAG");
				$writer->characters( $REGION7CONTENT );
				$writer->endTag("region_7_tag");
				print $output "\n";
				$writer->startTag("region_8_tag",
									"tag" => "$REGION9TAG");
				$writer->characters( $REGION8CONTENT );
				$writer->endTag("region_8_tag");
				print $output "\n";
				$writer->startTag("region_9_tag",
									"tag" => "$REGION9TAG");
				$writer->characters( $REGION9CONTENT  );
				$writer->endTag("region_9_tag");
				print $output "\n";
				$writer->startTag("region_10_tag",
									"tag" => "$REGION10TAG");
				$writer->characters( $REGION10CONTENT );
				$writer->endTag("region_10_tag");
				print $output "\n";
			$writer->endTag("extern_regions");
			print $output "\n";
		$writer->endTag("page_enhanced");
		print $output "\n";
	$writer->endTag("page");
	print $output "\n";

	$writer->end();
	$output->close();

	return "1";

}; # sub FormatXMLComplex(){}
########### Subroutine zur Erstellung der Output Datei in xml: Ende


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