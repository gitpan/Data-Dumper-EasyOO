#!perl

use Test::More;
eval "use Test::Warn";
plan skip_all =>
    "Test::Warn needed to test that warnings are properly issued"
    if $@;
plan tests => 7;

sub warning_is (&$;$);		# prototypes needed cuz eval delays
sub warning_like (&$;$);	# the protos provided by pkg

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
	      "got expected warning";

warnings_like ( sub { $ddez->Set(doodoo=>1,poop=>1) },
		[ qr/illegal method <doodoo>/,
		  qr/illegal method <poop>/ ],
		"got both expected warnings" );

warnings_are ( sub { $ddez->Set(doodoo=>1,poop=>1) },
		[ 'illegal method <doodoo>',
		  'illegal method <poop>' ],
		"got both expected warnings" );


