#!/usr/bin/perl
# Marpa::R3 is Copyright (C) 2017, Jeffrey Kegler.
#
# This module is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.10.1. For more details, see the full text
# of the licenses in the directory LICENSES.
#
# This program is distributed in the hope that it will be
# useful, but it is provided "as is" and without any express
# or implied warranties. For details, see the full text of
# of the licenses in the directory LICENSES.

# Various that share a calculator semantics

use 5.010001;

use strict;
use warnings;
use Test::More tests => 8;
use English qw( -no_match_vars );
use Scalar::Util qw(blessed);
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale(LC_ALL, "C");

use lib 'inc';
use Marpa::R3::Test;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R3;

my $calculator_grammar = Marpa::R3::Grammar->new(
    {   bless_package => 'My_Nodes',
        source        => \(<<'END_OF_SOURCE'),
:default ::= action => ::array bless => ::lhs
:start ::= Script
Script ::= Expression+ separator => comma bless => script
comma ~ [,]
Expression ::=
    Number bless => primary
    | ('(') Expression (')') assoc => group bless => parens
   || Expression ('**') Expression assoc => right bless => power
   || Expression ('*') Expression bless => multiply
    | Expression ('/') Expression bless => divide
   || Expression ('+') Expression bless => add
    | Expression ('-') Expression bless => subtract
Number ~ [\d]+

:discard ~ whitespace
whitespace ~ [\s]+
# allow comments
:discard ~ <hash comment>
<hash comment> ~ <terminated hash comment> | <unterminated
   final hash comment>
<terminated hash comment> ~ '#' <hash comment body> <vertical space char>
<unterminated final hash comment> ~ '#' <hash comment body>
<hash comment body> ~ <hash comment char>*
<vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
<hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_SOURCE
    }
);

my $productions_show_output = $calculator_grammar->productions_show();

Marpa::R3::Test::is( $productions_show_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'Scanless productions_show()' );
R1 [:start:] ::= Script
R2 Expression ::= Expression; prec=-1
R3 Expression ::= Expression; prec=0
R4 Expression ::= Expression; prec=1
R5 Expression ::= Expression; prec=2
R6 Expression ::= Number; prec=3
R7 Expression ::= '(' Expression ')'; prec=3
R8 Expression ::= Expression '**' Expression; prec=2
R9 Expression ::= Expression '*' Expression; prec=1
R10 Expression ::= Expression '/' Expression; prec=1
R11 Expression ::= Expression '+' Expression; prec=0
R12 Expression ::= Expression '-' Expression; prec=0
R13 Script ::= Expression +
R14 [:lex_start:] ~ Number
R15 [:lex_start:] ~ [:discard:]
R16 [:lex_start:] ~ '('
R17 [:lex_start:] ~ ')'
R18 [:lex_start:] ~ '**'
R19 [:lex_start:] ~ '*'
R20 [:lex_start:] ~ '/'
R21 [:lex_start:] ~ '+'
R22 [:lex_start:] ~ '-'
R23 [:lex_start:] ~ comma
R24 comma ~ [,]
R25 '(' ~ [\(]
R26 ')' ~ [\)]
R27 '**' ~ [\*] [\*]
R28 '*' ~ [\*]
R29 '/' ~ [\/]
R30 '+' ~ [\+]
R31 '-' ~ [\-]
R32 Number ~ [\d] +
R33 [:discard:] ~ whitespace
R34 whitespace ~ [\s] +
R35 [:discard:] ~ <hash comment>
R36 <hash comment> ~ <terminated hash comment>
R37 <hash comment> ~ <unterminated final hash comment>
R38 <terminated hash comment> ~ [\#] <hash comment body> <vertical space char>
R39 <unterminated final hash comment> ~ [\#] <hash comment body>
R40 <hash comment body> ~ <hash comment char> *
R41 <vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
R42 <hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
END_OF_SHOW_RULES_OUTPUT

# TODO -- Do I need the following as XPRs?
# R19 [:lex_start:] ~ Number
# R20 [:lex_start:] ~ [:discard:]
# R21 [:lex_start:] ~ '('
# R22 [:lex_start:] ~ ')'
# R23 [:lex_start:] ~ '**'
# R24 [:lex_start:] ~ '*'
# R25 [:lex_start:] ~ '/'
# R26 [:lex_start:] ~ '+'
# R27 [:lex_start:] ~ '-'
# R28 [:lex_start:] ~ comma

my $rules_show_output;
$rules_show_output = $calculator_grammar->g1_rules_show();

Marpa::R3::Test::is( $rules_show_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'Scanless g1_rules_show()' );
R0 Script ::= Expression +
R1 Expression ::= Expression
R2 Expression ::= Expression
R3 Expression ::= Expression
R4 Expression ::= Expression
R5 Expression ::= Number
R6 Expression ::= '(' Expression ')'
R7 Expression ::= Expression '**' Expression
R8 Expression ::= Expression '*' Expression
R9 Expression ::= Expression '/' Expression
R10 Expression ::= Expression '+' Expression
R11 Expression ::= Expression '-' Expression
R12 [:start:] ::= Script
END_OF_SHOW_RULES_OUTPUT

$rules_show_output = $calculator_grammar->l0_rules_show({ verbose => 1 });

Marpa::R3::Test::is( $rules_show_output,
    <<'END_OF_SHOW_RULES_OUTPUT', 'Scanless l0_rules_show()' );
R0 comma ~ [,]
R1 '(' ~ [\(]
R2 ')' ~ [\)]
R3 '**' ~ [\*] [\*]
R4 '*' ~ [\*]
R5 '/' ~ [\/]
R6 '+' ~ [\+]
R7 '-' ~ [\-]
R8 Number ~ [\d] +
R9 [:discard:] ~ whitespace
R10 whitespace ~ [\s] +
R11 [:discard:] ~ <hash comment>
R12 <hash comment> ~ <terminated hash comment>
R13 <hash comment> ~ <unterminated final hash comment>
R14 <terminated hash comment> ~ [\#] <hash comment body> <vertical space char>
R15 <unterminated final hash comment> ~ [\#] <hash comment body>
R16 <hash comment body> ~ <hash comment char> *
R17 <vertical space char> ~ [\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
R18 <hash comment char> ~ [^\x{A}\x{B}\x{C}\x{D}\x{2028}\x{2029}]
R19 [:lex_start:] ~ Number
R20 [:lex_start:] ~ [:discard:]
R21 [:lex_start:] ~ '('
R22 [:lex_start:] ~ ')'
R23 [:lex_start:] ~ '**'
R24 [:lex_start:] ~ '*'
R25 [:lex_start:] ~ '/'
R26 [:lex_start:] ~ '+'
R27 [:lex_start:] ~ '-'
R28 [:lex_start:] ~ comma
END_OF_SHOW_RULES_OUTPUT

do_test('Calculator 1', $calculator_grammar,
'42*2+7/3, 42*(2+7)/3, 2**7-3, 2**(7-3)' => qr/\A 86[.]3\d+ \s+ 126 \s+ 125 \s+ 16\z/xms);
do_test('Calculator 2', $calculator_grammar,
       '42*3+7, 42 * 3 + 7, 42 * 3+7' => qr/ \s* 133 \s+ 133 \s+ 133 \s* /xms);
do_test('Calculator 3', $calculator_grammar,
       '15329 + 42 * 290 * 711, 42*3+7, 3*3+4* 4' =>
            qr/ \s* 8675309 \s+ 133 \s+ 25 \s* /xms);

my $priority_grammar = <<'END_OF_GRAMMAR';
:default ::= action => ::array
:start ::= statement
statement ::= (<say keyword>) expression bless => statement
    | expression bless => statement
expression ::=
    number bless => primary
   | variable bless => variable
   || sign expression bless => unary_sign
   || expression ('+') expression bless => add
number ~ [\d]+
variable ~ [[:alpha:]] <optional word characters>
<optional word characters> ~ [[:alnum:]]*

# Marpa::R3::Display
# name: lexeme rule synopsis

:lexeme ~ <say keyword> priority => 1

# Marpa::R3::Display::End

<say keyword> ~ 'say'
sign ~ [+-]
:discard ~ whitespace
whitespace ~ [\s]+
END_OF_GRAMMAR

do_test(
    'Priority test 1',
    Marpa::R3::Grammar->new(
        {   bless_package => 'My_Nodes',
            source        => \$priority_grammar,
        }
    ),
    'say + 42' => qr/ 42 /xms
);

(my $priority_grammar2 = $priority_grammar) =~ s/priority \s+ => \s+ 1$/priority => -1/xms;
do_test(
    'Priority test 2',
    Marpa::R3::Grammar->new(
        {   bless_package => 'My_Nodes',
            source        => \$priority_grammar2,
        }
    ),
    'say + 42' => qr/ 41 /xms
);

sub do_test {
    my ( $name, $grammar, $input, $output_re, $args ) = @_;
    my $recce = Marpa::R3::Recognizer->new( { grammar => $grammar } );

    $recce->read(\$input);
    my $value_ref = $recce->value();
    if ( not defined $value_ref ) {
        die "No parse was found, after reading the entire input\n";
    }
    my $parse = { variables => { say => -1 } };
    my $value = ${$value_ref}->doit($parse);
    Test::More::like( $value, $output_re, $name );
}

sub My_Nodes::script::doit {
    my ($self, $parse) = @_;
    return join q{ }, map { $_->doit($parse) } @{$self};
}
sub My_Nodes::statement::doit {
    my ($self, $parse) = @_;
    return $self->[0]->doit($parse);
}

sub My_Nodes::add::doit {
    my ($self, $parse) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit($parse) + $b->doit($parse);
}

sub My_Nodes::subtract::doit {
    my ($self, $parse) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit($parse) - $b->doit($parse);
}

sub My_Nodes::multiply::doit {
    my ($self, $parse) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit($parse) * $b->doit($parse);
}

sub My_Nodes::divide::doit {
    my ($self, $parse) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit($parse) / $b->doit($parse);
}

sub My_Nodes::unary_sign::doit {
    my ($self, $parse) = @_;
    my ( $sign, $expression ) = @{$self};
    my $unsigned_result = $expression->doit($parse);
    return $sign eq '+' ? $unsigned_result : -$unsigned_result;
} ## end sub My_Nodes::unary_sign::doit

sub My_Nodes::variable::doit {
    my ( $self, $parse ) = @_;
    my $name = $self->[0];
    Marpa::R3::Context::bail(qq{variable "$name" does not exist})
        if not exists $parse->{variables}->{$name};
    return $parse->{variables}->{$name};
} ## end sub My_Nodes::variable::doit

sub My_Nodes::primary::doit {
    my ($self, $parse) = @_;
    return $self->[0];
}
sub My_Nodes::parens::doit  {
    my ($self, $parse) = @_;
    return $self->[0]->doit($parse);
}

sub My_Nodes::power::doit {
    my ($self, $parse) = @_;
    my ( $a, $b ) = @{$self};
    return $a->doit($parse)**$b->doit($parse);
}

# vim: expandtab shiftwidth=4:
