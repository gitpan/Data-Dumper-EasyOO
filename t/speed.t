#!perl

use Test::More (tests => 3);
use Benchmark();
use File::Spec;
use File::Temp 'tempfile';

use vars qw($AR $HR @Arrays);
require "t/TestLabelled.pm";

use Data::Dumper;
$Data::Dumper::Indent = $Data::Dumper::Indent = 1; # 2x - supress warnings

use_ok (Data::Dumper::EasyOO);

# open a couple different handles to collect output
my ($tmp) = tempfile("benchXXXX", SUFFIX => '.dat'); #, UNLINK => 1);
my $devnull = File::Spec->devnull;
open ($devnull, ">$devnull") or die "cant open $devnull: $!";

# build objects to benchmark against each other
my $ddo  = Data::Dumper->new([]);
my $ezdd = Data::Dumper::EasyOO->new(indent=>1);
# autoprint=0 forces print into void - no unfair advantage!
my $ezpr = Data::Dumper::EasyOO->new(indent=>1, autoprint=>$tmp);

SKIP: {
    eval "use Test::Benchmark";
    if ($@) {
	$ENV{TEST_VERBOSE} = 1;
	skip "need Test::Benchmark to run tests", 2;
    }
	
    $Test::Benchmark::VERBOSE = 1;	# see TBs output
    $Test::Benchmark::VERBOSE = 1;	# see TBs output

    is_fastest ('EzDDtmp', -3, {
	# print to temp file
	'DDtmp'    => sub { print $tmp Data::Dumper::Dumper($data) },
	'EzDDtmp'  => sub { print $tmp $ezdd->($data) },
    }, "ezdd faster");

    is_fastest ('EzDDnull', -3, {
	# print to /dev/null
	'DDnull'   => sub { print $devnull Data::Dumper::Dumper($data) },
	'EzDDnull' => sub { print $devnull $ezdd->($data) },
    }, "ezdd faster");
}


################################
# extra 'tests', which report results, but cant fail

exit unless $ENV{TEST_VERBOSE};

diag " running old 'tests'";

$Benchmark::VERSION ||= 0; # supress undef warnings

my $reps = $ENV{EZDD_TREPS} || -3;
my @tests =
    ({
	# DD is fastest, by a little
	'DD'	   => sub { Data::Dumper::Dumper ($data) },
	'DDtmp'    => sub { print $tmp Data::Dumper::Dumper($data) },
	'DDnull'   => sub { print $devnull Data::Dumper::Dumper($data) },
    }, {
	# without autoprint, 1st is 20x faster
	#'EzDDv'  => sub { $ezdd->($data) },
	'EzDDauto' => sub { $ezpr->($data) },
	'EzDDtmp'  => sub { print $tmp $ezdd->($data) },
	'EzDDnull' => sub { print $devnull $ezdd->($data) },
    });

for my $i (1..$#tests) {
    for $data ([$AR, $HR, @Arrays], $ezdd, $ddo) {
	my $rows;
	my @test = ($reps, $tests[$i], 'none');

	if ($Benchmark::VERSION == 1) {
	    $rows = Benchmark::cmpthese(@test);
	}
	elsif ($Benchmark::VERSION > 1) {
	    $rows = Benchmark::timethese(@test);
	    $rows = Benchmark::cmpthese($rows,'none');
	}
	else { # undef, ie 5.00503 
	    # this prints, and returns nothing
	    $rows = Benchmark::timethese(@test);
	    next;
	}
	report($rows);
    }
}

sub report {
    my $rows = shift;
    #next if (not $rows and not $Benchmark::VERSION) { 

    diag "";	# blank line for prettyness

    # kinda hacked way of getting output..
    if (ref $rows eq 'ARRAY') {
	# 5.8.2 situation - output-able table
	my $format = "%12s " x (@$rows + 1);
	for $r (@$rows) {
	    diag sprintf($format, @$r);
	}
    }
    elsif (ref $rows eq 'HASH') {
	# 5.6.2 situation: a labelled set of Benchmark results
	for $r (keys %$rows) {
	    my ($usr,$runs) = @{$rows->{$r}}[1,5];
	    diag sprintf("%6s %5d/%4.2f = %8.3f", $r, $runs, $usr, $runs/$usr);
	}
    }
    else {
	diag("please report this: cut-paste, to author\n"
	     ."perl $] Benchvers: $Benchmark::VERSION\n"
	     .$ezdd->("ezdd-format"=>$rows));
    }
}

__END__

