
print<<EOIntro;

To more thoroughly test this module, I recommend the following modules:
  Test::Output - to test autoprint => 1, autoprint => 2
  Test::Warn   - to verify warnings on errant usages

With them, you should get following results from `make testcover`


----------------------------------- ------ ------ ------ ------ ------ ------
File                                  stmt branch   cond    sub   time  total
----------------------------------- ------ ------ ------ ------ ------ ------
blib/lib/Data/Dumper/EasyOO.pm       100.0   96.7  100.0  100.0  100.0   99.3
Total                                100.0   96.7  100.0  100.0  100.0   99.3
----------------------------------- ------ ------ ------ ------ ------ ------


Yes, Im pleased with myself :-)

More to the point, if you install those things, and coverage is still
down significantly on your platform, let me know.  Thanks.

EOIntro


use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'Data::Dumper::EasyOO',
     license => 'perl',
     requires => {
	 'perl'           => '5.005_03',
	 'Data::Dumper'   => '2.00',
     },
     recommends => {
	 Test::Output => 0,
	 Test::Warn => 0,
       },
     create_readme => 1,
     );
$build->create_build_script;

