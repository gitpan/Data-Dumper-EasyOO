
use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'Data::Dumper::EasyOO',
     license => 'perl',
     requires => {
	 'perl'           => '5.005_03',
	 'Data::Dumper'   => '2.00',
     },
     );
$build->create_build_script;

