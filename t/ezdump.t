#!perl

use Test::More (tests => 8);

use_ok (Data::Dumper::EasyOO);

is(ezdump([1..3]), <<'EORef', "ezdump works w indent=2 (default)");
$VAR1 = [
          1,
          2,
          3
        ];
EORef

is($ezdump->indent(1), $ezdump, "alter ezdump's style, indent=1");

is(ezdump([1..3]), <<'EORef', "ezdump works w indent=1");
$VAR1 = [
  1,
  2,
  3
];
EORef


# re-import ezdump(), $ezdump, re-sets indent=2 default 
Data::Dumper::EasyOO->import(terse=>1);

is(ezdump([1..3]), <<'EORef', "re-import(terse=>1) re-sets indent=2"); 
[
          1,
          2,
          3
        ]
EORef


my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "object");
isa_ok ($ddez, 'CODE', "same object");

is(ezdump([1..3]), <<'EORef', "ezdump object preserves latest style imports");
[
          1,
          2,
          3
        ]
EORef

