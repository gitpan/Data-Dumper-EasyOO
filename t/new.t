#!perl
# test that new() accepts same options as Set
# also, test Title-case options here

use Test::More (tests => 40);
require "t/Testdata.pm";

use_ok (Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok $ddez, Data::Dumper::EasyOO;

is ($ddez->($AR), $ARGold[0][2], "new() on AR");
is ($ddez->($HR), $HRGold[0][2], "new() on HR");

diag "Copy Constructor";
my $newEz = $ddez->new;
isa_ok $newEz, Data::Dumper::EasyOO, "val from copy constructor";
is ($newEz->($AR), $ARGold[0][2], "cpyd-ezdd on AR");

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

diag "Copy Constructor with over-riding args";
my $Ez3 = $newEz->new(indent=>1);
isa_ok $Ez3, Data::Dumper::EasyOO, "val from copy constructor, w args";
is ($Ez3->($AR), $ARGold[0][1], "cpyd-ezdd on AR");
