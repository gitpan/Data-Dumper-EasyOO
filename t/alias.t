#!perl

use Test::More (tests => 10);

=head1 test Abstract

tests single and multiple aliases, in several different packages, to
make sure they dont trample on each other.

=cut

require 't/Testdata.pm';
# share imported pkgs via myvars to other pkgs in file
my ($ar,$hr) = ($AR, $HR);
my @argold = @ARGold;
my @hrgold = @HRGold;


use Data::Dumper::EasyOO (alias => 'EzDD');

my $ddez = EzDD->new();
is ($ddez->($AR), $ARGold[0][2], "alias => 'EzDD' into main");
is ($ddez->($HR), $HRGold[0][2], "alias => 'EzDD' into main");


package Foo;
use Data::Dumper::EasyOO (alias => Bar);
*is = \&Test::More::is;

$ddez = Bar->new(indent=>1);
is ($ddez->($ar), $argold[0][1], "alias into Bar, with indent=1");
is ($ddez->($hr), $hrgold[0][1], "alias into Bar, with indent=1");


package Double;
use Data::Dumper::EasyOO (alias => 'Alias1', alias => 'Alias2');
*is = \&Test::More::is;

$ddez = Alias1->new(terse=>1);
is ($ddez->($ar), $argold[1][2], "2 aliases, use 1st, w terse=1");
is ($ddez->($hr), $hrgold[1][2], "2 aliases, use 1st, w terse=1");

$ddez  = Alias2->new();
is ($ddez->($ar), $argold[0][2], "2 aliases, use 2nd");
is ($ddez->($hr), $hrgold[0][2], "2 aliases, use 2nd");


eval {
    $ddez = Bar->new();
};
print $@;

# qr/Can\'t locate object method "new" via package "Foo"/,
#     "no alias leaks between 2 (declared) pkgs in same file");


package Late;
use Data::Dumper::EasyOO;
import Data::Dumper::EasyOO (alias => ImportedAlias);
*is = \&Test::More::is;

$ddez = ImportedAlias->new(indent=>1);
is ($ddez->($ar), $argold[0][1], "imported (late) alias");
is ($ddez->($hr), $hrgold[0][1], "imported (late) alias");
