#!perl

my ($mdd, %style);
BEGIN { %style = (indent=>1, autoprint=>1) };

# 1st 2 work, last doesnt !
use Data::Dumper::EasyOO ( %style, init => \$mdd);
use Data::Dumper::EasyOO ( %style, init => \our $odd);	
use Data::Dumper::EasyOO ( %style, init => \my $ndd);	

$mdd->(mdd => \%INC);
$odd->(odd => \%INC);
$ndd->(ndd => \%INC);
