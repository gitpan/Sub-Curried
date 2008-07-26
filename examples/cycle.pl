#!/usr/bin/perl
use strict; use warnings;
use Sub::Curried;

# After a question in #moose by Debolaz

# use feature 'say'; # I can't get Devel::Declare to install on 5.10, bah
sub say {
    my @what = @_ || $_;
    print for @what, "\n";
}

# We want to be able to declare an infinite list of repeated values, for example
# (1,2,3,1,2,3,1,2,3) or in this case a list of functions (x2.5, x2, x2, ...)
curry cycle (@list) {
    my @curr = @list;
    return sub {
        @curr = @list unless @curr;
        return shift @curr;
        };
};

# we can't just use (*) like in Haskell :-)
curry times ($x,$y) { $x * $y };

curry mk_seq (@multipliers) {
    # This is an iterator to an infinite list of functions that multiply
    # by, for example, 2.5, 2, 2, 2.5, 2, 2, in turn
    return cycle([ map { times($_) } @multipliers ]);
};

curry scan_iterator ($it, $start) {
    my $next = $start;
    return sub {
        my $ret = $next;
        $next = $it->()->($next); # prepare next value;
        return $ret;
        };
};

curry iterator_to_array ($it, $count) {
    return map { $it->() } 1..$count;
};

say for iterator_to_array( 
        scan_iterator(
            mk_seq( [2.5, 2, 2] )
        )->(10) # start value
    )->(12); # number of iterations
