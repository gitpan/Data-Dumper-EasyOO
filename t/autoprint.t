#!perl

# autoprint => 1 causes EzDD obj to print to STDOUT if called in void
# context.  autoprint => 2 sends output STDERR

use Test::More (tests => 15);
use Cwd;
my $cwd = getcwd;
chomp $cwd;

diag "test void-context calls";
use_ok ( Data::Dumper::EasyOO );

my $ddez = Data::Dumper::EasyOO->new(indent=>1);
isa_ok ($ddez, 'Data::Dumper::EasyOO', "new() retval");

cleanup(); $!=0;

$Win32::IsWin95;

SKIP: {
    skip "redirect doesnt work on Win9x", 6 if $Win32::IsWin95;

    my $code;
    diag "Set() autoprint to STDOUT, STDERR";
    {
	$code = qq{ use lib q{$cwd/lib}; }
	. q{
	    use Data::Dumper::EasyOO;
	    my $ddez = Data::Dumper::EasyOO->new(indent=>1);
	    $ddez->Set(autoprint => 1);
	    $ddez->(foo => q{bar to stdout});
	    $ddez->Set(autoprint => 2);
	    $ddez->(foo => q{to stderr});
	};
	$code =~ s/\s+/ /msg;	# system() doesnt like newlines
	$code = ($^O =~ /MSWin/) ? qq{"$code"} : qq{'$code'};
	
	my @args = ($^X, '-e', $code, '>auto.stdout', '2>auto.stderr');
	my $cmd = join ' ', @args;
	qx{$cmd};
	warn "$? returned-by $cmd\n" if $?;
	
	unless ($^O =~ /MSWin/ or $^O =~ /cygwin/i) {
	    is (-s "auto.stdout", 24, "auto.stdout is expected size");
	    is (-s "auto.stderr", 20, "auto.stderr is expected size");
	} else {
	    is (-s "auto.stdout", 25, "auto.stdout is expected size");
	    is (-s "auto.stderr", 21, "auto.stderr is expected size");
	}
    }
    
    diag "autoprint => STDOUT at use-time, STDERR via Set()";
    {
	$code = qq{ use lib q{$cwd/lib}; }
	. q{
	    use Data::Dumper::EasyOO (autoprint => 1);
	    my $ddez = Data::Dumper::EasyOO->new(indent=>1);
	    $ddez->(foo => "bar to stdout");
	    $ddez->Set(autoprint => 2);
	    $ddez->(foo => "to stderr");
	};
	$code =~ s/\s+/ /msg;	# system() doesnt like newlines
	$code = ($^O =~ /MSWin/) ? qq{"$code"} : qq{'$code'};
	
	my @args = ($^X, '-e', $code, '>auto.stdout1', '2>auto.stderr1');
	my $cmd = join ' ', @args;
	qx{$cmd};
	warn"$? returned-by $cmd\n" if $?;
	
	unless ($^O =~ /MSWin/ or $^O =~ /cygwin/i) {
	    is (-s "auto.stdout1", 24, "auto.stdout1 is expected size");
	    is (-s "auto.stderr1", 20, "auto.stderr1 is expected size");
	} else {
	    is (-s "auto.stdout1", 25, "auto.stdout1 is expected size");
	    is (-s "auto.stderr1", 21, "auto.stderr1 is expected size");
	}
    }
    
    diag "override use-time: new(autoprint=>1), STDERR via Set()";
    {
	$code = qq{ use lib q{$cwd/lib}; }
	. q{
	    use Data::Dumper::EasyOO (autoprint => 2);
	    my $ddez = Data::Dumper::EasyOO->new(indent=>1, autoprint=>1);
	    $ddez->(foo => "bar to stdout");
	    $ddez->Set(autoprint => 2);
	    $ddez->(foo => "to stderr");
	};
	$code =~ s/\s+/ /msg;	    # system() doesnt like newlines
	$code = ($^O =~ /MSWin/) ? qq{"$code"} : qq{'$code'};
	
	my @args = ($^X, '-e', $code, '>auto.stdout2', '2>auto.stderr2');
	my $cmd = join ' ', @args;
	qx{$cmd};
	warn "$? returned-by $cmd\n" if $?;
	
	unless ($^O =~ /MSWin/ or $^O =~ /cygwin/i) {
	    is (-s "auto.stdout2", 24, "auto.stdout2 is expected size");
	    is (-s "auto.stderr2", 20, "auto.stderr2 is expected size");
	} else {
	    is (-s "auto.stdout2", 25, "auto.stdout2 is expected size");
	    is (-s "auto.stderr2", 21, "auto.stderr2 is expected size");
	}
    }
}


SKIP: {
    skip "this open() style not on 5.00503", 2 unless $] >= 5.006;
    diag "autoprint to open filehandle (ie GLOB)";

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
    my ($var,$io);
    # w/o eval, this breaks compile under 5.5.3 
    eval "open (\$io, '>', \\\$var)";
    warn $@ if $@;

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

    close $fh;
    # test size after closing. b4 is ng - os io sensitive
    unless ($^O =~ /MSWin/ or $^O =~ /cygwin/i) {
	is (-s "out.autoprint", 32, "output to file after setup");
    } else {
	is (-s "out.autoprint", 33, "output to file after setup");
    }
    $ddez->Set(autoprint => undef);
    warning_is ( sub { $ddez->(foo=>'bar') },
		 'called in void context, without autoprint set',
		 "expected warning after autoprint reset to undef");

}


unless ($ENV{TEST_VERBOSE}) {
    cleanup();
} else {
    diag "to see output files (normally deleted), set TEST_VERBOSE b4 test";
}

sub cleanup {
    unlink "auto.stderr2","auto.stdout2";
    unlink "auto.stderr1","auto.stdout1";
    unlink "auto.stderr","auto.stdout";
    unlink "out.autoprint";
}

__END__

