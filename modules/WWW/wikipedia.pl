#!/usr/bin/perl -Imodules

use WWW::Wikipedia;

$file = $ARGV[0];

die "perl $0 TEXTFILE.TXT" unless (defined($file));
print "\n########### Wikipedia->Bot() ###########\n\n";

open(RH,"<$file");
	my $content = do { local( $/ ) ; <RH> } ;
close RH;

@content = split(' ',$content);

open(WH,">$file.html") or die;
$| = 1;

foreach $search (@content){


	$tmp_search = $search;
	
	# hier alle sonderzeichen entfernen aus dem tmp_search
	$tmp_search =~ s/\.//ig;
	$tmp_search =~ s/,//ig;
	$tmp_search =~ s/;//ig;
	$tmp_search =~ s/-//ig;
	$tmp_search =~ s/\+//ig;
	$tmp_search =~ s/\)//ig;
	$tmp_search =~ s/\(//ig;
	
	print "Gesucht: $tmp_search ";
	
	my $wiki = WWW::Wikipedia->new(language => 'de');
	$wiki->timeout( 20 );
	my $result = $wiki->search( $tmp_search );
  
	if (defined($result)) {
  
		if ( $result->text() ) { 
			@text = split('\n', $result->text());
			
			print WH "<a href=\"wikilink\" title=\"@text[0] @text[1] @text[2]\">$search</a> ";
			print " - found\n";
			
		} else {
			print WH "$search ";
			print " - not found!\n";
		}
	}  else {
		print WH "$search ";
		print " - not found!\n";
	}

}
close WH;