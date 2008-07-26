#!/usr/bin/perl

=head1 NAME

Sub::Curried - Currying of subroutines via a new 'curry' declarator

=head1 SYNOPSIS

 curry add_n_to ($n, $val) {
    return $n+$val;
 };

 my $add_10_to = add_n_to( 10 );

 say $add_n_to->(4);  # 14

 # but you can also
 say add_n_to(10,4);  # also 14

 # or more traditionally
 say add_n_to(10)->(4);

=head1 DESCRIPTION

Currying and Partial Application come from the heady world of functional
programming, but are actually useful techniques.  Partial Application is
used to progressively specialise a subroutine, by pre-binding some of the
arguments.

Partial application is the generic term, that also encompasses the concept
of plugging in "holes" in arguments at arbitrary positions.  Currying is
(I think) more specifically the application of arguments progressively from
left to right until you have enough of them.

=cut

package Sub::Curried;
use strict; use warnings;
use Carp 'croak';

use Devel::Declare;
use Sub::Name;

our $VERSION = '0.04';

sub mk_my_var {
    my ($sigil, $name) = @_;
    my $shift = $sigil eq '$' ?
        'shift'
      : "${sigil}{+shift}";
    return qq[my $sigil$name = $shift;];
}
sub trim {
    s/^\s*//;
    s/\s*$//;
    $_;
}
sub get_decl {
    my $decl = shift;
    map trim, split /,/ => $decl;
}

sub import {
  my $package = caller();

  Devel::Declare->install_declarator(
    $package, 'curry', DECLARE_PACKAGE | DECLARE_PROTO,
    sub {
        my ($name, $decl) = @_;

        my @decl = get_decl($decl);

        my $string = join " ", map { # BUG in DD? can't be newline separated
            my ($vsigil, $vname) = /^([\$%@])(\w+)$/
                or die "Bad sigil: $_!"; # not croak, this is in compilation phase
            mk_my_var($vsigil, $vname);
            } @decl;

        return $string;
    },
    sub {
        my ($name, $decl, $sub, @rest) = @_;
        my @decl = get_decl($decl);

        my $make_f;
        $make_f = sub {
            my @filled = @_;
            return bless  sub {
                my @args = @_;
                my $expected = @decl;
                my $got      = @filled + @args;
                if ($got > $expected) {
                    croak "$name called with $got args, expected $expected";
                }
                elsif ($got == $expected) {
                    $sub->(@filled,@args);
                }
                else {
                    return $make_f->(@filled,@args);
                }
                }, __PACKAGE__;
            };
        my $f=$make_f->();
        if ($name) {
            no strict 'refs';
            subname $name =>$f;
            my $fqn = "${package}::${name}";
            *$fqn = $f;
        }
        return $f;
    }
  );
}

=head1 BUGS

Note that C<Devel::Declare> currently requires a trailing semicolon ";" after the C<curry>
declaration.

=head1 SEE ALSO

L<Devel::Declare> provides the magic (yes, there's a teeny bit of code
generation involved, but it's not a global filter, rather a localised
parsing hack).

There are several modules on CPAN that already do currying or partial evaluation:

=over 4

=item *

L<Perl6::Currying> - Filter based module prototyping the Perl 6 system

=item * 

L<Sub::Curry> - seems rather complex, with concepts like blackholes and antispices.  Odd.

=item *

L<AutoCurry> - creates a currying variant of all existing subs automatically.  Very odd.

=item *

L<Sub::DeferredPartial> - partial evaluation with named arguments (as hash keys).  Has some
great debugging hooks (the function is a blessed object which displays what the current
bound keys are).

=item *

L<Attribute::Curried> - exactly what we want minus the sugar.  (The attribute has
to declare how many arguments it's expecting)

=back

=head1 AUTHOR and LICENSE

 (c)2008 osfameron@cpan.org

This module is distributed under the same terms and conditions as Perl itself.

Please submit bugs to RT or shout at me on IRC (osfameron on #london.pm on irc.perl.org)

=cut

1;
