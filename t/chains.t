#!perl
# creates 1 EzDD, and alters it repeatedly, using both Set and AUTOLOAD

use Test::More (tests => 326);
require 't/Testdata.pm';

use_ok (Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good DDEz object");

diag "dump with default indent";
is ($ddez->($AR), $ARGold[0][2], "AR, with indent, terse defaults");
is ($ddez->($HR), $HRGold[0][2], "HR, with indent, terse defaults");

diag "test method chaining: ->Indent(\$i)->Terse(\$t)";
for my $t (0..1) {
    for my $i (0..3) {
	$ddez->Indent($i)->Terse($t);
	is ($ddez->($AR), $ARGold[$t][$i], "HR, with Indent($i)");
	is ($ddez->($HR), $HRGold[$t][$i], "HR, with Indent($i)");
    }
}

# methods: Values, Reset  cause failures in tests !

@methods = qw( Indent Terse Seen Names Pad Varname Useqq Purity
	       Freezer Toaster Deepcopy Bless Pair Maxdepth Useperl
	       Sortkeys Deparse );

diag "test that objects are returned from AUTOLOAD(), Set()";
for my $method (@methods) {
    isa_ok ($ddez->$method(), 'Data::Dumper::EasyOO', "\$ezdd->$method()\t");
}

diag "test that 2 method chains are ok";
for my $method (@methods) {
    for my $m2 (@methods) {
	isa_ok ( $ddez->$method()->$m2(),
		 'Data::Dumper::EasyOO',
		 "\$ezdd -> $method()\t-> $m2()\t" );
    }
}

__END__

for my $method (@methods) {
    print "$method returns: ", $ddez->$method(), "\n";
}

