#!perl

use Test::More (tests => 43);
require "t/TestLabelled.pm";

use_ok (Data::Dumper::EasyOO);
my $ezdd = Data::Dumper::EasyOO->new();

# uses a single object repeatedly, invokes with label => $data syntax
diag "test auto-labeling with combos of Terse(T), Indent(I)";

for my $t (0..1) {
    diag "following with Terse($t)";
    $ezdd->Terse($t);

    for my $i (0..3) {
	$ezdd->Indent($i);

	is ($ezdd->("indent$i" => $AR), $ARGold[$t][$i]
	    , "labeled AR, with Indent($i)" );
	is ($ezdd->("indent$i" => $HR), $HRGold[$t][$i]
	    , "labeled HR, with Indent($i)" );
    }
}

diag "two labeled data items, with combos of Terse(T), Indent(I)";

for my $t (0..1) {
    diag "following with Terse($t)";
    $ezdd->Terse($t);

    for my $i (0..3) {
	$ezdd->Indent($i);

	is ($ezdd->("indent$i" => $AR, "indent$i" => $HR)
	    , "$ARGold[$t][$i]" . "$HRGold[$t][$i]"
	    , "labeled AR and HR, with Indent($i)" );
    }
}

$ezdd->Set(Terse=>0,Indent=>2); # restore behavior matching DD default

diag "test un-labelling";	# exposed a bug!

for my $i (0..$#Arrays) {
    is ($ezdd->("item$i" => $Arrays[$i]), $LArraysGold[$i], "labeled-data[$i]");
    is ($ezdd->($Arrays[$i]),		  $ArraysGold[$i], "unlabeled-data[$i]");
}

diag "test programmer intended labelling, right and wrong";

for my $i (0..$#Arrays-1) {
    my $j = $i+1;
    is ($ezdd->("item$i" => $Arrays[$i], "item$j" => $Arrays[$j])
	, $LArraysGold[$i].$LArraysGold[$j],
	, "labeled-data[$i] and labeled-data[$j]");

    isnt ($ezdd->("item$i" => $Arrays[$i], $Arrays[$j])
	    , $LArraysGold[$i].$LArraysGold[$j],
	    , "labeled-data[$i] and un-labeled-data[$j]");
}

__END__

print Dumper \@Arrays;
print @ArraysGold;

for my $i (0..$#Arrays) {
    print "ok: ", $ezdd->("item$i" => $Arrays[$i]);
    print "vs: ", $ArraysGold[$i];
}
