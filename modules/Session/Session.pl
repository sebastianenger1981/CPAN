#!/usr/bin/perl	-Imodules

use Session::PHP;

my $SID_OBJ = Session::PHP->new();

my $PATH = $SID_OBJ->init();
my $SID = $SID_OBJ->SID();

%HASH = (
	"1"		=> "http://www.test.de",
	"2"		=> "asdfqawsef234f2w34",
);

# keine rückgabe
$SID_OBJ->put(\%HASH, $PATH, $SID);


# hash mit rückgabe der infos aus der session
my $HASH = $SID_OBJ->get($PATH, $SID);
print %$HASH;

$SID_OBJ->del($PATH, $SID);

