#!perl

use Benchmark qw(:all);
use IO::String;

use Test::More (tests => 2);
require "t/TestLabelled.pm";

use_ok (Data::Dumper);
use_ok (Data::Dumper::EasyOO);

$Data::Dumper::Indent=1;
my $ezdd = Data::Dumper::EasyOO->new(indent=>1);
my $ezpr = Data::Dumper::EasyOO->new(terse=>1,indent=>0);
my $ddo  = Data::Dumper->new([]);

diag ""; # new line..

#$ENV{HARNESS_VERBOSE} = 1;

for $data ($AR, $HR, [@Arrays], $ezpr, $ddo) {

    $rows = cmpthese(-3, {
	'DD'   => sub { Dumper ($data)},
	'EzDD' => sub { $ezdd->($data)},
    }, 'none');
    
    # kinda hacked way of getting output..
    for $r (@$rows) {
	diag sprintf("%12s %12s %12s %12s", @$r);
    }
}

__END__
