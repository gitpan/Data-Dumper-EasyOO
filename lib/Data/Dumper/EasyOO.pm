#!perl

package Data::Dumper::EasyOO;
use Data::Dumper();
use Carp 'carp';
use strict;

use 5.005_03;
use vars qw($VERSION);
$VERSION = '0.0502';

=head1 NAME

Data::Dumper::EasyOO - wraps DD for easy use of various printing styles

=head1 ABSTRACT

EzDD is an object wrapper around Data::Dumper (henceforth just DD),
and uses an inner DD object to produce all its output.  Its purpose is
to make DD's OO capabilities easier to use, ie to make it easy to:

 1. label your data meaningfully, not just as $VARx
 2. make and reuse EzDD objects
 3. customize print styles on any/all of them independently
 4. provide essentially all of DD's functionality
 5. do so with fewest keystrokes possible

=head1 SYNOPSIS

1st, an equivalent to DD's Dumper, which prints exactly like Dumper does

    use Data::Dumper::EasyOO;
    print ezdump([1,3]);

which prints:

    $VAR1 = [
              1,
              3
            ];

Here, we provide our own (meaningful) label, and use autoprinting, and
thereby drop the 'print' from all ezdump calls.


    use Data::Dumper::EasyOO (autoprint => 1);
    my $gl = { Joe => 'beer', Betsy => 'wine' });
    ezdump ( guest_list => $gl);

which prints:

    $guest_list = {
                    'Joe' => 'beer',
                    'Betsy' => 'wine'
                  };


And theres much more...

=head1 DESCRIPTION

EzDD wraps Data::Dumper, and uses an inner DD object to print/dump.
By default the output is identical to DD.  That said, EzDD gives you a
nicer interface, thus encouraging you to tailor DD output the way you
like it.

A primary design feature of EzDD is that you can choose your preferred
printing style in the 'use' statement.  EzDD replaces the usual
'import' semantics with the same (property => value) pairs as are
available in new().  

You can think of the use statement as a way to set new()'s default
behavior once, and reuse those styles (or override and supplement
them) on EzDD objects you create thereafter.

All of DD's style-setting methods are available in EzDD as both
properties to new(), and as object methods; its your choice.

=head2 An easy use of ezdump()

For maximum laziness support, ezdump() is exported into your
namespace, and supports the synopsis example.  $ezdump is also
exported; it is the EzDD object that ezdump() uses to do its dumping,
and allows you to tailor ezdump()s print-style.  It also lets you use
OO style if you prefer.

Continuing from 2nd synopsis example...

    $ezdump->Set(sortkeys=>1);
    ezdump ( guest_list => $gl );
    print "\n";
    $ezdump->Indent(1);
    ezdump ( guest_list => $gl );

which prints:

    $guest_list = {
                    'Betsy' => 'wine',
                    'Joe' => 'beer'
                  };

    $guest_list = {
      'Betsy' => 'wine',
      'Joe' => 'beer'
    };

The print-styles are set 2 times; 1st as a property setting, 2nd done
like a DD method.  The styles accumulate and persist on the object.


=cut

    ;
##############
# this (private) reference is passed to the closure to recover
# the underlying Data::Dumper object
my $magic = [];
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
my @okPrefs = qw( autoprint init _ezdd_noreset );

##############
sub import {
    # save EzDD client's preferences for use in new()
    my ($pkg, @args) = @_;
    my ($prop, $val, %args);
    my ($alias, @aliases, @ezdds);
    my $caller = caller();

    # handle aliases, multiples allowed (feeping creaturism)

    foreach my $idx (grep {$args[$_] eq 'alias'} reverse 0..$#args) {
	($idx, $alias) = splice(@args, $idx, 2);
	no strict 'refs';
	*{$alias.'::new'} = \&{$pkg.'::new'};
	*{$alias.'::import'} = \&{$pkg.'::import'};
	push @aliases, $alias;
    }
    # quietly accept 'imports' of things we export anyway
    foreach my $idx (grep {$args[$_] =~ /[\$\&]?ezdump$/} reverse 0..$#args) {
	splice(@args, $idx, 1);
    }

    while ($prop = shift(@args)) {
	$val = shift(@args);

	if (not grep { $_ eq $prop} @styleopts, @okPrefs) {
	    carp "unknown print-style: $prop";
	    next;
	}
	elsif ($prop ne 'init') {
	    $args{$prop} = $val;
	    push @ezdds, $val;
	}
	else {
	    carp "init arg must be a ref to a (scalar) variable"
		unless ref($val) =~ /SCALAR/;

	    carp "wont construct a new EzDD object into non-undef variable"
		if defined $$val;

	    $$val = Data::Dumper::EasyOO->new(%args);
	}
    }
    $cliPrefs{$caller} = \%args;	# save the allowed ones

    # export ezdump() unconditionally
    # no warnings 'redefine';
    local $SIG{__WARN__} = sub {
	carp $@, @_ unless $_[0] =~ / redefined/;
    };
    no strict 'refs';
    my $ezdump = $pkg->new(%args);
    ${$caller.'::ezdump'} = $ezdump; # export $ezdump = \&ezdump
    *{$caller.'::ezdump'} = $ezdump; # export ezdump()

    return (1, \%args) if wantarray;
    return (\%args) if defined wantarray;
    return;
}

sub Set {
    # sets internal state of private data dumper object
    my ($ezdd, %cfg) = @_;
    my $ddo = $ezdd;
    $ddo = $ezdd->($magic) if ref $ezdd eq __PACKAGE__;

    $ddo->{_ezdd_noreset} = 1 if $cfg{_ezdd_noreset};

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
    return $ezdd;
}

use vars '$AUTOLOAD';

sub AUTOLOAD {
    my ($ezdd, $arg) = @_;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    return if $meth eq 'DESTROY';
    my @vals = $ezdd->Set($meth => $arg);
    return $ezdd unless wantarray;
    return $ezdd, @vals;
}

sub pp {
    my ($ezdd, @data) = @_;
    $ezdd->(@data);
}

# Im ambivalent about this BEGIN block.  Its only use is to suppress
# redefined warnings issued when re-do{}'g the file, ie when purposely
# avoiding use or require (see t/redefined.t).  A more normal
# re-importing is already supressed in import(), by the same
# (localized) handler.

local $SIG{__WARN__};
BEGIN {
    $SIG{__WARN__} = sub {
	carp $@, @_ unless $_[0] =~ / redefined/;
    };
    *dump = \&pp;	# causes warning if done outside begin block
}

sub _ez_ddo {
    my ($ezdd) = @_;
    return $ezdd->($magic);
}

my $_privatePrinter;	# visible only to new and closure object it makes

sub new {
    my ($cls, %cfg) = @_;
    my $prefs = $cliPrefs{caller()} || {};

    my $ddo = Data::Dumper->new([]);	# inner obj w bogus data
    Set($ddo, %$prefs, %cfg);		# ctor-params override pkg-config

    #print "EzDD::new() ", Data::Dumper::Dumper [$prefs, \%cfg];

    my $code = sub { # closure on $ddo
	&$_privatePrinter($ddo, @_);
    };
    # copy constructor
    bless $code, ref $cls || $cls;
    
    if (ref $cls) {
	# clone its settings
	my $ddo = $cls->($magic);
	my %styles;
	@styles{@styleopts,@okPrefs} = @$ddo{@styleopts,@okPrefs};
	$code->Set(%styles,%cfg);
    }
    return $code;
}

$_privatePrinter = \&__DONT_TOUCH_THIS;

sub __DONT_TOUCH_THIS {
    my ($ddo, @args) = @_;

    unless ($ddo->{_ezdd_noreset}) {
	$ddo->Reset;	# clear seen
	$ddo->Names([]);	# clear labels
	$ddo->Values([]);	# clear data
    }
    if (@args == 1) {
	# test for AUTOLOADs special access
	return $ddo if defined $args[0] and $args[0] == $magic;
	
	# else Regular usage
	$ddo->{todump} = \@args;
    }
    elsif (@args % 2) {
	# cant be a hash, must be array of data
	$ddo->{todump} = \@args;
    }
    else {
	# possible labelled usage, 
	# check that all 'labels' are scalars
	
	my %rev = reverse @args;
	if (grep {ref $_} values %rev) {
	    # odd elements are refs, must print as array
	    $ddo->{todump} = \@args;
	}
	else {
	    while (@args) {
		push @{$ddo->{names}}, shift @args;
		push @{$ddo->{todump}}, shift @args;
	    }
	}
    }
  PrintIt:
    # return dump-str unless void context
    return $ddo->Dump() if defined wantarray;
    
    my $auto = (defined $ddo->{autoprint}) ? $ddo->{autoprint} : 0;
    
    unless ($auto) {
	carp "called in void context, without autoprint set";
	return;
    }
    # autoprint to STDOUT, STDERR, or HANDLE (IO or GLOB)
    
    if (ref $auto and (ref $auto eq 'GLOB' or $auto->can("print"))) {
	print $auto $ddo->Dump();
    }    
    elsif ($auto == 1) {
	print STDOUT $ddo->Dump();
    }
    elsif ($auto == 2) {
	print STDERR $ddo->Dump();
    }
    else { 
	carp "illegal autoprint value: $ddo->{autoprint}";
    }
    return;
};


1;

__END__

=head1 FEATURES

The following features are discussed in OO context, but are nearly all
applicable to ezdump() via its associated $ezdump object-handle.

=head2 Automatic Labelling of your data

EzDD 'knows' you prefer B<< labelled => $data >>, and assumes that
you've called it that way, except when you havent.  Any arglist that
looks like a list of pairs is treated as as such, by 2 rules:

  1. arglist length is even
  2. no candidate-labels are refs to other structures

so this B<labels> your data:

  $ezdd->(person => $person, place => $place);

but this doesn't (assuming that $person is an object, not a string):

  $ezdd->($person, $place);

If you find that EzDD sometimes misinterprets your array data, just
explicitly label it, like so:

    $ezdd->(some_label => \@yourdata);

DD::Simple does more magic labelling than EzDD (it grabs the name of
the variable being dumped), but EzDD avoids source filtering, and
gives you an unsuprising way to get what you want without fuss.


=head2 Dumping is default operation

EzDD recognizes that the only reason you'd use it is to dump your
data, so it gives you a shorthand to do so.

  print $ezdd->dump($foo);	# 'long' way
  print $ezdd->pp($foo);	# shorter way
  print $ezdd->($foo);		# look Ma, no function name

It helps to think of an EzDD object as analogous to a printer;
sometimes you want to change the paper-tray, or the landscape/portrait
orientation, but mostly you just want to print.


=head2 Dumping without calling 'print'

To save more keystrokes, you can set autoprint => 1, either at
use-time (see synopsis), or subequently.  Printing is then done for
you when you call the object.

    $ezdd->Set(autoprint=>1);	# unless already done
    $ezdd->($foo);		# even shorter

But this happens only when you want it to, not when you assign the
results to something else (or return it into your own print statement)

    $b4 = $ezdd->($foo);	# save rendering in var
    $foo->bar();		# alter printed obj

    # now dump before and after
    print "before: $b4, after: ", $ezdd->($foo);


=head2 setting print styles (on existing objects)

You can set an object's print-style by imitating the way you'd do it
with object oriented DD.  All of DDs style-changing methods are
emulated this way, not just the 2 illustrated here.

    $ezdd->Indent(2);
    $ezdd->Terse(1);

You can chain them too:

    $ezdd->Indent(2)->Terse(1);

=head2 setting print styles using B<Set()>

The emulation above is really dispatched to Set(); those 2 examples
above can be restated:

    $ezdd->Set(indent => 2)->Set(terse => 1);

or more compactly:

    $ezdd->Set(indent => 2, terse => 1);

Multiple objects' print-styles can be altered independently of each
other:

    $ez2->Set(%addstyle2);
    $ez3->Set(%addstyle3);

For maximum laziness, mixed-case versions of both method calls and
properties are also supported.


=head2 Creating new printer-objects

Create a new printer, using default style:

    $ez3 = Data::Dumper::EasyOO->new();

Create a new printer, with some style overrides that are passed to
Set():

    $ez4 = Data::Dumper::EasyOO->new(%addstyle);

Clone an existing printer:

    $ez5 = $ez4->new();

Clone an existing printer, with style overrides:

    $ez5 = $ez4->new(%addstyle2);


=head2 Dumping to other filehandles

    # obvious way
    print $fh $ezdd->($bar);

    # auto-print way
    $ezdd->Set(autoprint => $fh);
    $ezdd->($bar);

You can set autoprint style to any open filehandle, for example
\*STDOUT, \*STDERR, or $fh.  For convenience, 1, 2 are shorthand for
STDOUT, STDERR.  autoprint => 0 turns it off.

TBC: autoprint => 3 prints to fileno(3) if it's been opened, or warns
and prints to stdout if it hasnt.


=head2 Namespace aliasing

Data::Dumper::EasyOO is cumbersome to type more than once in a
program, and is unnecessary too.  Just provide an alias at use-time,
and then use that alias thereafter.

   use Data::Dumper::EasyOO ( alias => 'EzDD' );
   $ez6 = EzDD->new();

=head2 use-time object initialization

If calling C<< $ez1 = EzDD->new >> is too much work, you can
initialize it by passing it at use time.

    use Data::Dumper::EasyOO ( %style, init => \our $ez );

By default, $ez is initialized with DD's defaults, these can be
overridden by %style.

If you want to store the handle in C<< my $ez >>, then declare the
myvar prior to the use statement, otherwize the object assigned to it
at BEGIN time is trashed at program INIT time.

    my $ez;
    use Data::Dumper::EasyOO ( init => \$ez );

=head2 use-time multi-object initialization

You can even create multiple objects at use-time.  EzDD treats the
arguments as an order-dependent list, and initializes any specified
objects with the settings seen thus far.  To better clarify, consider
this example:

  use Data::Dumper::EasyOO 
    (
     alias => EzDD,
     # %DDdefstyle,	# since we use a DD object, we get its default style
     %styleA,
     init => \$ez1,	# gets DDdef and styleA
     %styleB,
     init => \$ez2,	# gets DDdef, styles A and B
     %styleC,
     init => \$ez3,	# gets DDdef, styles A, B and C
     %styleD,
     );

This is equivalent:

  use Data::Dumper::EasyOO (alias => 'EzDD');
  BEGIN {
    $ez1 = EzDD->new(%DDdefstyle, %styleA);
    $ez2 = EzDD->new(%DDdefstyle, %styleA, %styleB);
    $ez2 = EzDD->new(%DDdefstyle, %styleA, %styleB, %styleC );
  }

Each %style can supplement or override the previous ones.  %styleD is
not used for any of the initialized objects, but it is incorporated
into the using package's default style, and is used in all new objects
created at runtime.

Each user package can set its own default style; you can use this, for
example, to set a different sortkeys => \&pkg_filter for each.  With
this, YourReport::Summary and YourReport::Details can dump the info
appropriate for your needs.

=head2 re-importing to change print-style defaults

If you decide during runtime that you dont like your use-time
defaults, just call import again to change them.  All newly built
objects will inherit those new print-styles.

=head1 A FEATURE-FULL EXAMPLE

This is a rather over-the-top usage.

1st, it sets an alias, with which you can shorten calls to new().
2nd, it sets several of my favorite print styles.  3rd, it initializes
several dumper objects, giving each of them slightly different
print-styles.

 my $ezdd;	# declare a handle for an object to be initialized

 use Data::Dumper::EasyOO
    (
     alias	=> EzDD,	# a temporary top-level-name alias
     
     # set some print-style defaults
     indent	=> 1,		# change DD's default from 2
     sortkeys	=> 1,		# a personal favorite

     # autoconstruct a printer obj (calls EzDD->new) with the defaults
     init	=> \$ezdd,	# var must be undef b4 use

     # set some more default print-styles
     terse	=> 1,	 	# change DD's default of 0
     autoprint	=> $fh,		# prints to $fh when you $ezdd->(\%something);

     # autoconstruct a 2nd printer object, using current print-styles
     init	=> \our $ez2,	# var must be undef b4 use

     alias	=> Ez2,		# another top-level-name alias
     );

 $ezdd->(p1 => $person);	# print as '$p1 => ...'

 my $foo = EzDD->new(%style)	# create a printer, via alias, w new style
    ->(there => $place);	# and print with it too.

 $ez2-> (p2 => $person);	# dump w $ez2, use its style

 $foo->(here => $where);	# dump w $foo style (use 2 w/o interference)

 $foo->Set(%morestyle);		# change style at runtime
 $foo->($_) foreach @things;	# print many things

=head1 Other conveniences

=head2 dump() and pp()

These are both object methods, and are aliases which provide a
familiar invocation for users of Data::Dump.

  # these are all the same
  $ezdump->(\%INC);
  $ezdump->pp(\%INC);
  $ezdump->dump(\%INC);

=head1 IMPORTS

This module pollutes the users namespace with 2 symbols: $ezdump and
&ezdump.  In the context of maximum easyness, this is construed to be
a feature.

=head1 BUGS

If you 'use strict' and this module together, you may get weird
errors; similar to the following.  The last ones in particular are
odd, since the code has NO variable named $class.

 Variable "$ezdump" is not imported at t/ezdump-strict.t line 18.
  at t/ezdump-strict.t line 18
        (Did you mean &class instead?)
  at t/ezdump-strict.t line 18
 Variable "$ezdump" is not imported at t/ezdump-strict.t line 18.
  at t/ezdump-strict.t line 18
        (Did you mean &ezdump instead?)
  at t/ezdump-strict.t line 18
 Global symbol "$class" requires explicit package name at t/ezdump-strict.t line 18.
 Global symbol "$ezdump" requires explicit package name at t/ezdump-strict.t line 18.

I dont know the root cause of this, but the solution is simple;
predeclare the $ezdump variable, as is done in t/ezdump-strict.t (the
file proves that explicit importing of those default imports doesnt
fix the oddity shown above).

=head1 Caveats, Todos, Tobe Considered

Print-style defaults are stored in EzDD for each user package.  This
does not permit aliases to have separate defaults, which could be
useful.  This is fairly straightforward, and may be added in the
future.

Aliases could be treated like object 'init's, in that they could get
defaults based upon the print-styles seen thus far in the use-time
arguments.  The difficulty with this idea is that it changes the
declarative flavor of aliases.  In the featureful example above, the
EzDD alias appears before the various print-style settings, so they
would not apply to it, but only to the 2nd alias, Ez2.


=head1 SEE ALSO (its a crowded space, isnt it!)

 L<Data::Dumper>		the mother of them all
 L<Data::Dumper::Simple>	nice interface, basic feature set
 L<Data::Dumper::EasyOO>	easyest of them all :-)
 L<Data::Dump>			has cool feature to squeeze data
 L<Data::Dump::Streamer>	highly accurate, evaluable output
 L<Data::TreeDumper>		lots of output options

=head1 AUTHOR

Jim Cromie <jcromie@cpan.org>

Copyright (c) 2003,2004,2005 Jim Cromie. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__END__

