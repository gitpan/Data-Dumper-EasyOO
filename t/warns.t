#!perl

use Test::More (tests => 5);
eval "use Test::Warn";
plan skip_all =>
    "Test::Warn needed to test that warnings are properly issued"
    if $@;

sub warning_is (&$;$);		# prototypes needed cuz eval delays
sub warning_like (&$;$);	# those provided by pkg

use_ok (Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good object");
isa_ok ($ddez, 'CODE', "good object");

print $ddez->([1,2,3]);

diag "test for disallowed methods";

# traditional form (not the one docd in the Test::Warns pod)
# is needed here, cuz the eval delays the prototype.

warning_is { $ddez->poop(1) } 'illegal method <poop>',
	     "got expected warning";

warning_like { $ddez->Set(Indent=>1,poop=>1) }
	      qr/illegal method <(Indent|poop)>/,
	      "got one of expected warnings";


