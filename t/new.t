#!perl
# test that new() accepts same options as Set
# also, test Title-case options here

use Test::More (tests => 35);
require "t/Testdata.pm";

use_ok (Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();

is ($ddez->($AR), $ARGold[0][2], "new() on AR");
is ($ddez->($HR), $HRGold[0][2], "new() on HR");

diag "accept both lowercase and titlecase";
for $t (0..1) {
    for $i (0..3) {
	$ddez = Data::Dumper::EasyOO->new(indent=>$i,terse=>$t);
	is ($ddez->($AR), $ARGold[$t][$i], "new(indent=>$i,terse=>$t) on AR");
	is ($ddez->($HR), $HRGold[$t][$i], "new(indent=>$i,terse=>$t) on HR");
	
	$ddez = Data::Dumper::EasyOO->new(Indent=>3-$i,terse=>$t);
	is ($ddez->($AR), $ARGold[$t][3-$i], "new(Indent=>3-$i,terse=>$t) on AR");
	is ($ddez->($HR), $HRGold[$t][3-$i], "new(Indent=>3-$i),terse=>$t) on HR");
    }
}
