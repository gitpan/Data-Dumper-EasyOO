#!perl

use Test::More tests => 6;

use vars q($odd);
my ($mdd, %style); # cant declare inside use
BEGIN { %style = (indent=>1, autoprint=>1) };
# BEGIN { $mdd = 'foo' } # causes carp if uncommented

# 2 imports, each inits an object
use_ok Data::Dumper::EasyOO => (%style, init => \$mdd);
use_ok Data::Dumper::EasyOO => (%style, init => \$odd);	
# works, but our not on 5.00503
#use_ok Data::Dumper::EasyOO => (%style, init => \our $odd);

isa_ok ($mdd, Data::Dumper::EasyOO);
isa_ok ($odd, Data::Dumper::EasyOO);

diag "test copy constructor";
my $ndd = $mdd->new;
$ndd->Indent(2);

$mdd->(mdd => \%INC);
$ndd->(copied => \%INC);

SKIP: {
    eval "use Test::Warn";
    skip "these tests need Test::Warn", 2 if $@;
    diag "test (init => \$var) where \$var is already defined";

    my $code = qq{ use Data::Dumper::EasyOO (init => \\\$odd) };
    #print "code: $code, with $odd\n";
    warning_like ( sub { eval "$code" },
		 qr/wont construct a new EzDD object into non-undef variable/,
		 'Auto-Construct only into variable w/o a defined value');

    $odd = undef;
    eval "$code";
    isa_ok ($odd, Data::Dumper::EasyOO, 're-construct after undeffing var.');
}

__END__


$odd->(odd => \%INC);
