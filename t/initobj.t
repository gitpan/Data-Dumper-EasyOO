#!perl

use Test::More tests => 9;

use vars q($odd);
my ($mdd, %style); # cant declare inside use
BEGIN { %style = (indent=>1, autoprint=>1) };
# BEGIN { $mdd = 'foo' } # causes carp if uncommented

# 2 imports, each inits an object
use_ok Data::Dumper::EasyOO => (%style, init => \$mdd);
use_ok Data::Dumper::EasyOO => (%style, init => \$odd);	
# works, but not with 'our' on 5.00503
#use_ok Data::Dumper::EasyOO => (%style, init => \our $odd);

isa_ok ($mdd, Data::Dumper::EasyOO);
isa_ok ($odd, Data::Dumper::EasyOO);

pass "test copy constructor";
my $ndd = $mdd->new;
$ndd->Indent(2);

$mdd->(mdd => \%INC);
$ndd->(copied => \%INC);

SKIP: {
    eval "use Test::Warn";
    skip "these tests need Test::Warn", 3 if $@;
    pass "test (init => \$var) where \$var is already defined";

    my $code = qq{ use Data::Dumper::EasyOO (init => \\\$odd) };
    #print "code: $code, with $odd\n";
    warning_like ( sub { eval "$code" },
		 qr/wont construct a new EzDD object into non-undef variable/,
		 'Auto-Construct only into variable w/o a defined value');

    $odd = undef;
    eval "$code";
    isa_ok ($odd, Data::Dumper::EasyOO, 're-construct after undeffing var.');
}

SKIP: {
    eval "use Config";
    skip "these tests need Test::Warn", 1 
	unless $Config::Config{useperlio};

    # strcat in eval's arg to prevent compile-time parse, 
    # which would cause 5.5.3 to barf on 3 arg open
    eval "".q{
    	my $buf;
	open (my $fh, '>', \$buf);
	$odd->Set(autoprint => $fh);
	$odd->(odd => \%INC);

	like ($buf, qr/PerlIO/,
	      "autoprint => \$fh works on use-time init'd obj");
    };
    warn $@ if $@;
}


