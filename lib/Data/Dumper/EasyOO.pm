#!perl

package Data::Dumper::EasyOO;	# pod at __END__
use Data::Dumper();
use Carp 'carp';

use 5.005_03;
use vars qw($VERSION);
$VERSION = 0.03_01;

##############
my %cliPrefs;	# stores style preferences for each client package

# DD print-style options/methods/package-vars/attributes.
# Theyre delegated to the inner DD object, and 'importable' too.

my @styleopts;	# used to validate methods in Set()

# 5.00503 shipped with DD v2.101
@styleopts = qw( indent purity pad varname useqq terse freezer
		    toaster deepcopy quotekeys bless );

push @styleopts, qw( maxdepth )
    if $Data::Dumper::VERSION ge '2.102';	# with 5.6.1

push @styleopts, qw( pair useperl sortkeys deparse )
    if $Data::Dumper::VERSION ge '2.121';	# with 5.6.2

# DD methods; also delegated
my @ddmethods = qw ( Seen Values Names Reset );

# EzDD-specific importable style preferences
my @okPrefs = qw( autoprint );

##############
sub import {
    # save EzDD client's preferences for use in new()
    my ($pkg, @args) = @_;
    $DB::single=1;
    my %args = @args;
    #for my $prop (keys %args) {
    for my $prop (@args) {
	$val = shift @args;
	if ($prop eq 'init') {
	    carp "already initialized" if defined $$val;#args{$prop};
	    my $foo = delete $args{$prop};
	    $$foo = Data::Dumper::EasyOO->new(%args);
	    next;
	}
	unless (grep { $_ eq $prop} @styleopts, @okPrefs) {
	    delete $args{$prop};
	    carp "unknown style-pref: $prop";
	}
    }
    $cliPrefs{caller()} = {%args};	# save the allowed ones
    #print "EzDD client cache: ", Data::Dumper::Dumper \%cliPrefs;
}

sub Set {
    # sets internal state of private data dumper object
    my ($ezdd, %cfg) = @_;
    my $ddo = $ezdd;
    $ddo = $ezdd->('__SA__') if ref $ezdd eq __PACKAGE__;

    for my $item (keys %cfg) {
	#print "$item => $cfg{$item}\n";
	my $attr = lc $item;
	my $meth = ucfirst $item;

	if (grep {$attr eq $_} @styleopts) {
	    $ddo->$meth($cfg{$item});
	}
	elsif (grep {$item eq $_} @ddmethods) {
	    $ddo->$meth($cfg{$item});
	}
	elsif (grep {$attr eq $_} @okPrefs) {
	    $ddo->{$attr} = $cfg{$item};
	}
	else { carp "illegal method <$item>" }
    }
    $ezdd;
}

sub AUTOLOAD {
    my ($ezdd, $arg) = @_;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    return if $meth eq 'DESTROY';
    my @vals = $ezdd->Set($meth,$arg);
    print "wantarray, @vals\n" if wantarray;
    return $ezdd unless wantarray;
    return $ezdd, @vals;
}

sub new {
    my ($cls, %cfg) = @_;
    my $prefs = $cliPrefs{caller()} || {};

    my $ddo = Data::Dumper->new([]);	# bogus data, required
    Set($ddo, %$prefs, %cfg);		# ctor-config overrides pkg-config

    #print "EzDD::new() ", Data::Dumper::Dumper [$prefs, \%cfg];

    my $code = sub { # closure on $ddo
	my @args = @_;

	unless ($ddo->{_ezdd_noreset}) {
	    $ddo->Reset;	# clear seen
	    $ddo->Names([]);	# clear labels
	}
	if (@args == 1) {
	    # test for AUTOLOADs special access
	    return $ddo if defined $args[0] and $args[0] eq '__SA__';

	    # else Regular usage
	    $ddo->{todump} = \@args;
	    goto PrintIt;
	}
	# else
	if (@args % 2) {
	    # cant be a hash, must be array of data
	    $ddo->{todump} = \@args;
	    goto PrintIt;
	}
	else {
	    # possible labelled usage, 
	    # check that all 'labels' are scalars
	    
	    my %rev = reverse @args;
	    if (grep {ref $_} values %rev) {
		# odd elements are refs, must print as array
		$ddo->{todump} = \@args;
		goto PrintIt;
	    }
	    my (@labels,@vals);
	    while (@args) {
		push @labels, shift @args;
		push @vals,   shift @args;
	    }
	    $ddo->{names}  = \@labels;
	    $ddo->{todump} = \@vals;
	    goto PrintIt;
	}
      PrintIt:
	# return dump-str unless void context
	return $ddo->Dump() if defined wantarray;

	no warnings 'uninitialized';
	my $auto = $ddo->{autoprint};
	carp "called in void context, without autoprint set"
	    and return unless defined $auto;
	    
	# autoprint to STDOUT, STDERR, or HANDLE (IO or GLOB)

	if ($auto == 1) {
	    print STDOUT $ddo->Dump();
	}
	elsif ($auto == 2) {
	    print STDERR $ddo->Dump();
	}
	elsif (ref $auto and $auto->isa('IO') || $auto->isa('GLOB')) {
	    print $auto $ddo->Dump();
	}
	else { 
	    carp "dunno whatis $ddo->{autoprint}";
	}
	return;

    };
    return bless $code, $cls;
}

sub pp {
    my ($ezdd, @data) = @_;
    $ezdd->(@data);
}

*dump = \&pp;

1;

__END__

=head1 NAME

Data::Dumper::EasyOO - wraps DD for easy use of printing styles

=head1 SYNOPSIS

 {
     # set common style for all objects created
     use Data::Dumper::EasyOO (indent => 1);

     # build an EzDD object, adding print-styles
     my $ezdd = Data::Dumper::EasyOO->new (terse => 1);
     
     # use the same ezdd obj repeatedly
     print "default: ", $ezdd->($_) for @userdata;
     
     # label it $foo, not $VAR1
     print $ezdd->(foo => $_) for @userdata;
     
     # alter printing style using DD API
     $ezdd->Terse(0);
     print "default: ", $ezdd->($_) for @userdata;
     
     # alter many print styles at once
     $ezdd->Set (terse=>0, sortkeys=>1);
     print "default: ", $ezdd->($_) for @userdata;

     # set autoprint to STDOUT
     $ezdd->Set (autoprint => 1);
     $ezdd->( you_used_pkgs => \%INC);

     # set autoprint to an opened filehandle
     $ezdd->Set (autoprint => $fh);
     $ezdd->( you_used_pkgs => \%INC);
 }

=head1 DESCRIPTION

This package wraps Data::Dumper, and gives an object thats as easy to
print with as Dumper(), DDs exported procedural interface.  Its also
easy to control print-style, as theyre set within the EzDD object.

In this document, I use DD as shorthand for Data::Dumper, DD-OO for
its object oriented API, and EzDD for this class.  Despite the package
name, I assume some knowledge about DD, at least wrt explaining why
EzDD is better.

In DD-OO, you must provide new() with the data to print, then change
print-style, then print.  This 3 step usage tends to be verbose.
Because theres no (currently documented) way to un-bind the data, most
users just toss the DD object.

In contrast, EzDD is geared for object reuse, just think of it like a
printer; print-style is analogous to color, paper-size, etc.  You just
build an object for each different print style you want, and use them
repeatedly.  A single EzDD object is enough for most users.

=head1 FEATURE COMPARISON

In the following, I compare EzDD to either or both DD and DD-OO.  This
section is meant to be somewhat cursory; the next section delves a bit
deeper.

=head2 construct the EzDD object

To use EzDD, you have to (blow a line of code to) create an EzDD
object, but you can initialize it once and for all, with less typing
than with DDs package vars.

    new:   $ezdd = Data::Dumper::EasyOO->new(indent=>1,sortkeys=>1);
    old: {
	$Data::Dumper::Indent = 1;
	$Data::Dumper::Sortkeys = 1;
    }

=head2 EzDD printing is brief

Once your $ezdd object is built, printing is as easy as using
Dumper().  Note that $ezdd doesnt even need a method name !

    new:   print $ezdd->($foo);
     dd:   print Dumper ($foo);
  dd_oo:   print Data::Dumper->Dump($foo);

Using autoprint mode, you can drop the 'print'

    $ezdd->Set(autoprint=>1);
    $ezdd->($foo);

=head2 Easier Labelling of Data

  old: print Data::Dumper->Dump ( [$a,$b,$c], [qw(a b c)] );
  new: print $ezdd	 ->	( a=>$a, b=>$b, c=>$c )

Labelling data wih DD-OO is counterintuitive; most perl users like and
expect to see C<< labelled => $data >>.  DD-OO is also too punctuation
intensive, too dependent on having exactly 2 arrayref args, and having
them the same length.  Also, note that Dumper() cannot label data at all.

=head2 You can independently control print-style on each object 

With Dumper(), print-style is controlled either globally, or by
localizing a set of variables.  With EzDD, print-style can be set on
the object.  This is a big advantage when you want 2 styles
simultaneously.

  DD: {
      local $Data::Dumper::Indent = 1;
      local $Data::Dumper::Sortkeys = 1;
      print Dumper (\@foo);
  }
  new: {
      $ezdd->Set(indent=>1,sortkeys=>1); # do once on obj
      print $ezdd->(\@foo);
  }

The next example shows DD_OO style control.  Its tedious if you have
to do it each time you want to print.

=head2 You can print repeatedly with same object

In DD-OO, you must provide the data to be dumped when the object is
created, only then can the print-style be changed.  This means lots of
extra typing and method calls, thus discouraging use of OO style.

  EzDD: {
      $d->Set(indent=>1,deepcopy=>1);
      print $d->($_) foreach @data;
  }
  DD_OO:
    foreach $datum (@data) {
	$d = Data::Dumper->new($datum);
	$d->Sortkeys(1)->Indent(1)->Deepcopy(1);
	print $d->Dump;
    }


=head1 FEATURES

=head2 Controlling Print Style for objects

With EzDD, you control print style of single objects, either by
speifying at creation, or altering thereafter.

    $ezdd = Data::Dumper::EasyOO->new(%printOptions);
    $ezdd->Set(%newprintOptions);	# update many
    $ezdd->Indent(1); 			# update by DDs methods
    $ezdd->Terse(1)->Sortkeys(1);	# update in chains (like DD)

These settings stay with the object thru its lifetime, and are
independent of other objects settings.  If you dont set preferences as
above, DDs globals are used by default.

=head2 Controlling Print Style via use

Print style can also be set at use-time, these are defaults for every
object built thereafter.  They can be overridden for individual
objects, by any of new(), Set(), or DDs style-setting methods.

The styles are saved separately for each package using EzDD, so Foo.pm
and Bar.pm can have a different styles.

=head2 Easy Labelling for your Data

    print $ezdd->(@args);

@args are treated as pairs of labelled data if possible; ie if
arglist is even length, and if the 'labels' are scalars.  If you have
an array (of scalars) that is incorrectly printed as labelled data,
you can force things by passing its ref; ie $ezdd->([0..3]) vs
$ezdd->((0..3)).

This maybe a bit aggressive for your tastes, but I dont use DD with
simple scalars (except by accident ;-) and my habit with Dumper() is
to always pass a single data-arg anyway, ex \@foo.  YMMV.  FWIW -
DD::Dumper() also does this; it calls Data::Dumper->Dump([@_]). For
more specifics, check t/labels.t or the code.

=head2 Auto-Printing

Autoprinting allows you to drop the 'print':

    use Data::Dumper::EasyOO ( autoprint => 1 );
    my $ez = Data::Dumper::EasyOO->new();
    $ez->('the-includes' => \%INC);

The autoprint property can be 1 for STDOUT, 2 for STDERR, or an open
FileHandle, and will write accordingly.  You can also change this
afterwards (note the tag change);

    my $ez2 = EzDD->new(_ezdd_autoprint => 2);	# set in ctor
    $ez->Set(_ezdd_autoprint => 2);		# change during use

=head2 Speed 

Dumper() builds a new DD object for each print, and this has non-zero
runtime costs.  Ive included a benchmark in the testsuite which shows
3% to 24% improvement on a linux 686 laptop, using the small data
chunks I used for testing.  With large data sets, printing time
dominates, and the improvement drops asymtotically to 0%.


=head1 INTERFACE 

As I hope is clear by now, $ezdd->($data) renders the data.

new(%printOptions) creates a new EzDD object, and calls Set() to
establish desired printing behavior of that instance.

Set(%printOptions) alters the print style of an existing EzDD object.
It accepts option names matching the methods that DD provides, and
lowercase versions of them.  %option values are not validated by EzDD,
DD itself may do so, but I havent tested this, and make no promises.

Set() also does not provide accessor functionality; most DD methods
return the DD object in support of method chaining, they cannot return
the attribute values.

AUTOLOAD() allows you to invoke the familiar DD methods on an EzDD
object, its a convenience method which calls Set().

pp() and dump() are methods to "pretty-print".  The names were
borrowed from C<Data::Dump>

=head1 IMPLEMENTATION

The class builds a blessed CODEref object, for which perl also allows
method-lookups.  This hybrid nature is key to the viability of the
design.

new() builds a private Data::Dumper object, then builds and returns a
closure on that object.  The closure provides the printing interface
directly, and also provides (via special data value - slightly
hackish) access to the underlying DD object for the other methods;
Set() and AUTOLOAD().

=head1 BUGS

EasyOO relys on Data::Dumper, so if youre using 5.00503 and havent
upgraded DD, some print-style controls wont be available.  

Validation of DD methods is based on checks of $DD::VERSION, and may
have a few errors, or may miss a few DD versions in between original
and current.

Some allowed methods may be nonsense in this context; I havent used
them all myself in real-life, or in tests.

Theres no accessor functionality for print-styles.

=head1 Possible Applications

A client-class dumper.  You can create one or a few EzDD objects in
your Foo.pm module, and tailor them to serialize Foo objects however
you like.  With B<Sortkeys>, you can serialize only the object keys
you want, for persistent storage, or for debugging purposes.
Maxdepth, Varname, etc are all similarly usable.


=head1 CAVEATS, Enhancements, TBD, TBC

=over 4

=item method-less invocation may be over-cool.

This was an experiment (in blessed coderefs) that went well enough to
continue.  If this feature makes you itch, you can use $ezdd->pp()
$ezdd->dump() instead.

=item Brand new code, with the usual caveats.

Tested OK against 5.005_03, 5.8.2, and many in between, both threaded
and unthreaded.  As wise men say, 'release early, release often'

=item Too much dependency on DD

The down-side of 5.00503 compatibility is that DD was less capable
back then.  Barbie caught and reported some test failures on
ActiveState 5.6.1 due to then non-existent DD methods used in some
aggressive tests.  Ive detuned t/chains.t, but others may lurk.

=item No validation on %printOptions values.

Arrayrefs & hashrefs are passed verbatim to DD object.  If DD expects
a particular value type, you must provide it; I do no checking, and
rely on DD to complain as fitting.

If DD carps about stuff passed in, it may blame EzDD.  I regard this
as a user error, youve been warned.  I will accept patches which
place blame properly ;-)

=item format control not per-use, but on object only

You cant localize print options for 1 usage.  This is because those DD
pkg vars, localized or not, are copied into the object when its
constructed, and are thereafter ignored by that object.  This *could*
be fixed by changes to DD, but I dont see the value, Id anticipate a
slowdown, and I dont expect DDs maintainer would accept that.

=item auto-labelling may be overzealous.

In particular, $ezdd->(1,2,3,4) will treat 1,3 as labels.
At minimum it needs more tests.

=item Reporting of illegal methods can change capitalization

DD has nice property that object attributes are lower-cased versions
of the method names.  I leverage this, and use lc(), ucfirst() to
allow mixed case print-styles, but this may result in slightly
confusing capitalization differences.

=item not *entirely* data-agnostic

C<< $ezdd->('__SA__') >> will return underlying DD object, unlike all
other data.  This hackery is needed cuz the closure is the only handle
to the DD object, unless Ive missed something.

=item add no_reset option

EzDD uses $ddo->Reset so that $ddo can be reused.  a no_reset option
would allow you to defeat that.  The internal flag 'ddez_noreset'
already exists, but the details are subject to change.

=back

=head1 To Be Considered

=over 4

=item AUTOLOAD() accessor mode

This conflicts with support for method-chaining (ie returning the
object so it can be chained).  Since DD supports it, we should too.

It may be possible by defining sub _get($prop), calling it from
AUTOLOAD if not @args.  This would break chaining for accessors, but
thats 'broken by design' anyway.

=item Sortkeys as hashref

If sortkeys was a hashref (with arrayref values), the keys *could*
specify applicability of the arrayref based upon the data being
dumped; its type, depth, tag, etc.. See L<Possible Applications>.  

Reasons not to bother: The key would need som XPath-ish form, which
may be sufficient reason to kill the idea at birth.  It would also
need DD support, at very least a callback scheme.

=back

=head2 Comments welcome.

    Whats overkill ?

=head1 SEE ALSO

L<Data::Dumper> is used internally (you know by now ;-).  If you
really want to, you can reuse DD objects without this module.  See the
code for how to do so.

L<Data::Dump> also has a simple interface, ie a single function,
imported as dump() or pp().  It doesnt have print-style controls, and
doesnt have DDs evaluable output, so its not directly usable in place
of DD, where this is.  On the other hand, its output is magically
data-dependent; if the data fits on a single line, it gets printed
that way.

=head1 ACKNOWLEDGMENTS

Gurusamy Sarathy for writing DD, I love it and use it *ALL* the time,
its often my microscope of choice.  I cant leave the above critique as
the only commentary.  

=head1 AUTHOR

Jim Cromie <jcromie@cpan.org>

Copyright (c) 2003 Jim Cromie. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

I dont suppose I'll ever recover the (modest) development time via
reduced keystrokes, but CPAN has saved me so much already; heres a
little give-back.  And besides, perl is fun, like an always-new toy.

=cut


	if ($auto == 0) {
	    # print anyway - hack for benchmarking..
	    print STDOUT $ddo->Dump();
	}
