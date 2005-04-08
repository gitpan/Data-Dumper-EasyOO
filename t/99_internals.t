#!perl

# various tests to get better testcover-age
# some of these tests dont reflect real use-cases

use Test::More (tests => 8);
#require "t/Testdata.pm";

use_ok (Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, Data::Dumper::EasyOO, "object");


# test inner Data::Dumper object handle
my $ddo = $ddez->_ez_ddo();
isa_ok ($ddo, Data::Dumper, "inner object");

# test empty call
is($ddez->(), "", "nothing dumped when called wo args");


# test noreset functionality (
$ddez->Set( _ezdd_noreset => 1);

is($ddez->(foo=>'bar'), qq{\$foo = 'bar';\n}, "basic dump");
is($ddez->(bar=>'baz'), qq{\$bar = 'baz';\n}, "basic dump");

# a 'this-never-happens' call to new
$ddez = Data::Dumper::EasyOO::new(0);

# but resulting object still works. yay.
is($ddez->(foo=>'bar'), qq{\$foo = 'bar';\n}, "basic dump");
is($ddez->(bar=>'baz'), qq{\$bar = 'baz';\n}, "basic dump");

__END__

is ($ddez->($AR), $ARGold[0][2], "new() on AR");
is ($ddez->($HR), $HRGold[0][2], "new() on HR");

pass "Copy Constructor";
my $newEz = $ddez->new;
isa_ok $newEz, Data::Dumper::EasyOO, "val from copy constructor";
is ($newEz->($AR), $ARGold[0][2], "cpyd-ezdd on AR");

pass "accept both lowercase and titlecase";
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

pass "Copy Constructor with over-riding args";
my $Ez3 = $newEz->new(indent=>1);
isa_ok $Ez3, Data::Dumper::EasyOO, "val from copy constructor, w args";
is ($Ez3->($AR), $ARGold[0][1], "cpyd-ezdd on AR");
