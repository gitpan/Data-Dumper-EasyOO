#!perl

package Data::Dumper::EasyOO;
use Data::Dumper;

use 5.005_03;
use vars qw($VERSION);
$VERSION = 0.01;

=head1 NAME

Data::Dumper::EasyOO - wraps DD for easy use of printing styles

=head1 SYNOPSIS

use Data::Dumper::EasyOO;

 {
    # build an EzDD object
    my $ezdd = Data::Dumper::EasyOO->new(indent=>1,terse=>1);

    # use the same ezdd obj repeatedly
    print "default: ", $ezdd->($_) for @userdata;

    # label it $foo, not $VAR1
    print "labelled: ", $ezdd->(foo => $_) for @userdata;

    # alter printing style using DD API, and reuse object
    $ezdd->Indent(0);
    print "default: ", $ezdd->($_) for @userdata;

    # alter many print styles at once
    $ezdd->Set ( indent=>1, terse=>0, sortkeys=>1 );
    print "default: ", $ezdd->($_) for @userdata;
 }

=head1 DESCRIPTION

This package wraps Data::Dumper, and adapts its API for easier control
of output format.

In the following, I often use DD as shorthand for Data::Dumper, OO
for its Object Oriented API, and EzDD for this class.

Here are what I see as Data::Dumper OO API usage problems:

=head2 calls to OO-DD are Too Verbose

For everything but exported Dumper(), invoking DD is baroque.  This
class assumes that printing data is why you want the object, and makes
its use as easy/brief as possible; you dont even need a method name!

    print $ezdd->($foo);

=head2 Too Hard to Label data

    print Data::Dumper->Dump([$a,$b,$c], [qw(a b c)]);

This non-OO usage is just too punctuation intensive, too dependent on
having exactly 2 arrayref args, and the label position is
counterintuitive; ie after the data (ie: B<< tag => value >>).

=head2 Format Control is Cumbersome

{
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    print Dumper (@foo);
}

Without using OO form, your only choice wrt print-style is either
localizing package variables each time you use Data::Dumper, or
changing them globally.

=head2 Early Binding of Data

    # OO usage
    foreach $datum (@data) {
	$d = Data::Dumper->new($datum);
	$d->Purity(1)->Terse(1)->Deepcopy(1);
	print $d->Dump;
    }

In DD OO, you must provide the data to be dumped when the object is
created.  Only afterwards can you control that objects print format.
This means lots of extra typing and function calls, thus discouraging
use of OO style.  I often live with indent=2, which I personally find
harder to read than indent=1.

=head1 FEATURES

=head2 Brief-as-possible printing

    print $ezdd->($yourdata)

In other words, theres no method, just the object handle, the arrow,
and the parenthesized arguement list.

=head2 Easy Control of Printing Style

With EzDD, you can control print style of a single object, either by
speifying at creation, or altering thereafter.

    $ezdd = Data::Dumper::EasyOO->new(%printOptions);
    $ezdd->Set(%newprintOptions);
    $ezdd->Indent(1);

=head2 Auto-Labelling

Arguments are checked to see if they can be interpreted as labels, ie
values at odd indexes must be scalars.  If this test passes, the data
is rendered using DD labelling feature, see L<"Too Hard to Label
Data"> above.

This maybe a bit aggressive for your tastes, but I dont use DD with
simple scalars (except by accident ;-) and my habit with Dumper() is
to always pass a single data-arg anyway, ex \@foo.  YMMV.  For more
specifics, check t/labels.t or the code.

=head2 Speed 

Dumper() builds a new DD object for each print, and this has non-zero
runtime costs.  Ive included a benchmark in the testsuite which shows
3% to 24% improvement on a linux 686 laptop, using the small data
chunks I used for testing.  With large data sets, that improvement
will asymtotically drop to 0%.

=head1 INTERFACE 

As I hope is clear by now, $ezdd->($data) renders the data

new(%printOptions) creates a new EzDD object, and calls Set() to
establish desired printing behavior of that instance.

Set(%printOptions) alters the print style of an existing EzDD object.
It accepts option names matching the methods that DD provides, and
lowercase versions of them.  %option values are not validated by EzDD,
DD itself may do so, but I havent tested this, and make no promises.

Set() also does not provide accessor functionality; most DD methods return
the DD object in support of method chaining, and thus cannot return
the attribute values.


AUTOLOAD() allows you to invoke the familiar DD methods on an EzDD
object, its a convenience method which calls Set().


=head1 IMPLEMENTATION

The class builds a blessed CODEref object, for which perl also allows
method-lookups.  This hybrid nature is key to the viability of the
design.

new() builds a private Data::Dumper object, then builds and returns a
closure on that object.  The closure provides the printing interface
directly, and also provides (via special data value - slightly
hackish) access to the underlying DD object for the other methods;
Set() and AUTOLOAD().


=head1 Possible Applications

A client-class dumper.  With a singleton in a pkg-var or file-my-var,
you can set the B<sortkeys> attr to dump only the object keys you care
to see for debugging purposes.  A small number of such specialists
should serve all your needs.

For nested structures this may be insufficient; you may wish to print
different parts of different substructures.

=head1 CAVEATS, Enhancements, TBD, TBC

As wise men say, 'release early, release often'

=over 4

=item method-less invocation may be over-cool.

After all, $d->dump() (see L<Data::Dump>) isnt so verbose, and I may
add one here, subject to feedback.  This was an experiment (in blessed
coderefs) that went well enough to continue.  This experiment should
be apparent below...

=item Brand new code, with the usual caveats.

It tested good against 5.005_03, so blessed coderefs must be OK ;-)  

=item Too much dependency on DD attributes.

This is partly, mostly, or completely solvable with existing DD
methods.  I still need to decide on the 'right' way to check for
methods in DD to forward to, 3 choices are apparent; just try it in an
eval block, check the symbol table, check for attributes in the dd
hash.  Each is imperfect.

=item No validation on %printOptions values.

arrayrefs & hashrefs are passed verbatim to DD object TBD iff needed,
theyll be derefed first.

=item format control not per-use, but on object only

You cant localize print options for 1 usage.  This is because those DD
pkg vars, localized or not, are copied into the object when its
constructed.  This *could* be fixed by changes to DD, but I dont see
the value, and Id anticipate a slowdown.

=item no global format control

Im considering 'import' tags to control globally, ex C<< use
Data::Dumper::EasyOO qw(indent=>1,useqq=>1) >>.  The problem with this
is that each user package may want different style.  import() would
have to store a custom hash per package, and new() would have to use
it.  Such overhead may not be worth it.

=item auto-labelling may be overzealous.

In particular, $ezdd->(1,2,3,4) will treat 1,3 as labels.
At minimum it needs more tests.

=item flexibility wrt capitalization of attr/methods.

can issue warnings with different capitalization from usage.

=item not *entirely* data-agnostic

C<< $ezdd->('__SA__') >> will return underlying DD object, unlike all
other data.  This hackery is needed cuz the closure is the only handle
to the DD object, unless Ive missed something.  I could protect it by
checking the caller package, but I dont want a gun in the house.

=item add no_reset option

EzDD uses $ddo->Reset so that $ddo can be reused.  a no_reset option
would allow you to defeat that.  the internal flag 'ddez_noreset'
already exists

=item settle on validation in Set()

Set() currently contains several mechanisms to validate %printoptions,
none of which are perfect; symbol-table-check VS attr-check VS
eval{$ddo->$meth($val)}.

=back

=head1 To Be Considered

=over 4

=item no-print printing.

C<< $ezdd->($foo) >> could print if called in void context.  Tell me
 if you think so, and what its import or un-import symbol should be.

=item functor style is too magical ?

I could export-ok a dump(), like Data::Dump, enable it with an
'import' control

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

L<Data::Dumper> is used internally (you know by now ;-)

L<Data::Dump> also has a simple interface, ie a single function,
imported as dump() or pp().  It doesnt have print-style controls, and
doesnt have DDs statement syntax, so its not directly usable for
eval-able output.  However, its output is magically data-dependent; if
it fits on a single line, it prints that way.

=head1 ACKNOWLEDGMENTS

Gurusamy Sarathy for writing DD, I love it and use it *ALL* the time,
its often my microscope of choice.  I cant leave the above critique as
the only commentary.  

=head1 AUTHOR

Jim Cromie <jcromie@cpan.org>

Copyright (c) 2003 Jim Cromie. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

I dont suppose Ill ever recover the (modest) development time via
reduced keystrokes, but CPAN has saved me so much already; heres a
little give-back.  And besides, perl is fun, like an always-new toy.

=cut

##################

package Data::Dumper::EasyOO;
use Data::Dumper;
use Carp 'carp';

sub AUTOLOAD {
    my ($ezdd, $arg) = @_;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    return if $meth eq 'DESTROY';
    my @vals = $ezdd->Set($meth,$arg);
    print "wantarray, @vals\n" if wantarray;
    return $ezdd unless wantarray;
    return $ezdd, @vals;
}

# 1 forces method test via symbol table
my $viasymtbl = 0;	# 1 doesnt work !

sub Set {
    # sets internal state of private data dumper object
    my ($ezdd, %cfg) = @_;
    my $ddo = $ezdd;
    $ddo = $ezdd->('__SA__') if ref $ezdd eq __PACKAGE__;
    #print "setting ddo: ", Dumper $ddo, \%cfg if %cfg;


    for my $item (keys %cfg) {
	#print "$item => $cfg{$item}\n";

	if ($viasymtbl) {
	    # this chunk doesnt work!
	    my $meth = ucfirst $item;
	    unless (\&{"Data::Dumper::$meth"}) {
		carp "illegal $item on DDobj\n"
		    .\&{"Data::Dumper::$meth"};
		next;
	    }
	    $ddo->$meth($cfg{$item});
	}
	else { # direct ddo update
	    my $meth = ucfirst $item;
	    my $attr = lc $item;
	    unless (exists $ddo->{$attr}) {
		carp "illegal method <$attr>";
		next;
	    }
	    # maybe this is better, skip all that noise above
	    eval { $ddo->$meth($cfg{$item}) };
	    carp "illegal method <$attr>" if $@;
	}
    }
    $ezdd;
}

sub new {
    my ($cls, %cfg) = @_;

    my $ddo = Data::Dumper->new([]); # bogus data
    Set($ddo, %cfg);

    my $code = sub { # closure on $ddo
	my @args = @_;

	unless ($ddo->{ddez_noreset}) {
	    $ddo->Reset;	# clear seen
	    $ddo->Names([]);	# clear labels
	}
	if (@args == 1) {
	    # test for AUTOLOADs special access
	    return $ddo if defined $args[0] and $args[0] eq '__SA__';

	    # else Regular usage
	    $ddo->{todump} = \@args;
	    return $ddo->Dump();
	}
	# else
	if (@args % 2) {
	    # cant be a hash, must be array of data
	    $ddo->{todump} = \@args;
	    return $ddo->Dump();
	}
	else {
	    # possible labelled usage, 
	    # check that all 'labels' are scalars

	    my %rev = reverse @args;
	    if (grep {ref $_} values %rev) {
		# odd elements are refs, must print as array
		$ddo->{todump} = \@args;
		return $ddo->Dump();
	    }
	    my (@labels,@vals);
	    while (@args) {
		push @labels, shift @args;
		push @vals,   shift @args;
	    }
	    $ddo->{names}  = \@labels;
	    $ddo->{todump} = \@vals;
	    return $ddo->Dump();
	}
    };
    return bless $code, $cls;
}

#############################
# sanity test, tb removed

package main;

if ($0 =~ /EasyOO\.pm$/) {

    $foo = [qw/ hello there /];
    $bar = {qw/ alpha 1 beta 2 zed 26 /};
    
    $baseline = Data::Dumper->new([$foo], ['foo']);
    print $baseline->Dump();

    my $ezdd = Data::Dumper::EasyOO->new;
    print "new thingy: ", Dumper $ezdd;
    
    print "used on \$foo: ", $ezdd->($foo);
    print "used on \$bar: ", $ezdd->($bar);

    print "w label \$foo: ", $ezdd->(foo=>$foo);
    print "w label \$bar: ", $ezdd->(bar=>$bar);
    
    $ezdd->Indent(1);
    print "used on $foo: ", $ezdd->($foo);

    $ezdd->Set(indent=>1,sortkeys=>1);
    print "used on bar: ", $ezdd->($bar);

    $ezdd->poop(1);
    
    #print "used on $foo: ", $ezdd->($foo);
}

1;

__END__

