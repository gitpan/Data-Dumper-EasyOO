#!perl

# autoprint => 1 causes EzDD obj to print to STDOUT if called in void
# context.  autoprint => 2 sends output STDERR

use Test::More (tests => 15);

diag "test void-context calls";
use_ok ( Data::Dumper::EasyOO ); #=> (autoprint => 2));

my $ddez = Data::Dumper::EasyOO->new(indent=>1);
isa_ok ($ddez, 'Data::Dumper::EasyOO', "new() retval");

my $code;
diag "Set() autoprint to STDOUT, STDERR";
{
    $code = qq{ use lib "$ENV{PWD}/lib"; }
    . q{
	use Data::Dumper::EasyOO;
	my $ddez = Data::Dumper::EasyOO->new(indent=>1);
	$ddez->Set(autoprint => 1);
	$ddez->(foo => q{bar to stdout});
	$ddez->Set(autoprint => 2);
	$ddez->(foo => q{to stderr});
    };
    
    $code =~ s/\s+/ /msg;	# system() doesnt like newlines
    # print "code: $code\n";
    
    system ("$^X -e '$code' > auto.stdout 2> auto.stderr");  # call code via -e
    print "errs: $! $@" if $! or $@;
    unless ($^O =~ /MSWin/) {
	is (-s "auto.stdout", 24, "stdout is expected size");
	is (-s "auto.stderr", 20, "stderr is expected size");
    } else {
	is (-s "auto.stdout", 25, "stdout is expected size");
	is (-s "auto.stderr", 21, "stderr is expected size");
    }
}

diag "autoprint => STDOUT at use-time, STDERR via Set()";
{
    $code = qq{ use lib "$ENV{PWD}/lib"; }
    . q{
	use Data::Dumper::EasyOO (autoprint => 1);
	my $ddez = Data::Dumper::EasyOO->new(indent=>1);
	$ddez->(foo => "bar to stdout");
	$ddez->Set(autoprint => 2);
	$ddez->(foo => "to stderr");
    };
    
    $code =~ s/\s+/ /msg;	# system() doesnt like newlines
    # print "code: $code\n";
    
    system ("$^X -e '$code' > auto.stdout1 2> auto.stderr1");  # call code via -e
    print "errs: $! $@" if $! or $@;
    unless ($^O =~ /MSWin/) {
	is (-s "auto.stdout1", 24, "stdout is expected size");
	is (-s "auto.stderr1", 20, "stderr is expected size");
    } else {
	is (-s "auto.stdout1", 25, "stdout is expected size");
	is (-s "auto.stderr1", 21, "stderr is expected size");
    }
    #unlink "auto.stderr1","auto.stdout1";
}

diag "override use-time: new(autoprint=>1), STDERR via Set()";
{
    $code = qq{ use lib "$ENV{PWD}/lib"; }
    . q{
	use Data::Dumper::EasyOO (autoprint => 2);
	my $ddez = Data::Dumper::EasyOO->new(indent=>1, autoprint=>1);
	$ddez->(foo => "bar to stdout");
	$ddez->Set(autoprint => 2);
	$ddez->(foo => "to stderr");
    };
    
    $code =~ s/\s+/ /msg;	# system() doesnt like newlines
    # print "code: $code\n";
    
    system ("$^X -e '$code' > auto.stdout2 2> auto.stderr2");  # call code via -e
    print "errs: $! $@" if $! or $@;
    unless ($^O =~ /MSWin/) {
	is (-s "auto.stdout2", 24, "stdout is expected size");
	is (-s "auto.stderr2", 20, "stderr is expected size");
    } else {
	is (-s "auto.stdout2", 25, "stdout is expected size");
	is (-s "auto.stderr2", 21, "stderr is expected size");
    }
}

diag "autoprint to open filehandle (ie GLOB)";
{
    open (my $fh, ">out.autoprint") or die "cant open out.autoprint: $!";
    $ddez->Set(autoprint => $fh);
    $ddez->(foo => 'to file');
    close $fh;
    eval { $ddez->(foo => 'to file') };
    like ($!, qr/Bad file (number|descriptor)/,
	"got expected err writing to closed file: $!");
    
    if ($^O =~ /MSWin/) {
	is (-s "out.autoprint", 19, "file is expected size");
    } else {
	is (-s "out.autoprint", 18, "file is expected size");
    }
}


SKIP: {
    eval "use IO::String";
    skip "these tests need IO::String", 1 if $@;
    diag "test autoprint => IO using IO::string";

    $io = IO::String->new(my $var);
    $ddez->Set(autoprint => $io);
    $ddez->(foo => 'bar to stdout');
    is (length $var, 24, "length of IO::string storage");
    #print "wrote: $var";
}


SKIP: {
    skip "these tests need 5.8.0", 1 if $] < 5.008;
    diag "test autoprint => IO using 5.8 open (H, '>', \\\$scalar)";
    my $var;
    open (my $io, '>', \$var);

    $ddez->Set(autoprint => $io);
    $ddez->(foo => 'bar to stdout');
    is (length $var, 24, "length ok");
    #print "wrote: $var";
}

SKIP: {
    eval "use Test::Warn";
    skip "these tests need Test::Warn", 3 if $@;
    diag "test autoprint invocation w.o setup";

    my $ddez = Data::Dumper::EasyOO->new(indent=>1);
    warning_is ( sub { $ddez->(foo=>'bar') },
		 'called in void context, without autoprint set',
		 "expected warning b4 setup");

    open (my $fh, ">out.autoprint") or die "cant open out.autoprint: $!";
    $ddez->Set(autoprint => $fh);
    $ddez->(ok => 'yeah');
    $ddez->(foo => 'to file');

    # test size after closing. b4 is ng - os io sensitive
    #is (-s "out.autoprint", 32, "output to file");
    close $fh;
    is (-s "out.autoprint", 32, "output to file after setup");

    $ddez->Set(autoprint => undef);
    warning_is ( sub { $ddez->(foo=>'bar') },
		 'called in void context, without autoprint set',
		 "expected warning after autoprint reset to undef");

}


unless ($ENV{TEST_VERBOSE}) {
    unlink "auto.stderr1","auto.stdout1";
    unlink "auto.stderr","auto.stdout";
    unlink "out.autoprint";
} else {
    diag "to see output files (normally deleted), set TEST_VERBOSE b4 test";
}

__END__

IM UNDECIDED ON THIS - SHOULD autoprint => 0 carp and print ??
THIS WAS MOSTLY FOR BENCHMARKING - TO GET 
{
    eval "use Test::Warn";
    skip "these tests need Test::Warn", 3 if $@;
    diag "test that autoprint=>0 warns and prints";

    $code = qq{ use lib "$ENV{PWD}/lib"; }
    . q{
	use Test::More tests => 1;
	use Test::Warn;
	use Data::Dumper::EasyOO (autoprint => 0);
	my $ddez = Data::Dumper::EasyOO->new;

	warning_is (sub { $ddez->(foo => "bar to stdout") },
		    "called in void context, without autoprint set",
		    "expected warning b4 setup");
		    
	$ddez->Set(autoprint => 1);
	$ddez->(foo => "to stdout");
    };
    
    $code =~ s/\s+/ /msg;	# system() doesnt like newlines
    # print "code: $code\n";
    
    system ("$^X -e '$code' > auto.stdout1 2> auto.stderr1");  # call code via -e
    print "errs: $! $@" if $! or $@;
    unless ($^O =~ /MSWin/) {
	is (-s "auto.stdout1", 24, "stdout is expected size");
	is (-s "auto.stderr1", 20, "stderr is expected size");
    } else {
	is (-s "auto.stdout1", 25, "stdout is expected size");
	is (-s "auto.stderr1", 21, "stderr is expected size");
    }
}

