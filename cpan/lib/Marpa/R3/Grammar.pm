# Copyright 2016 Jeffrey Kegler
# This file is part of Marpa::R3.  Marpa::R3 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R3 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R3.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::R3::Grammar;

use 5.010001;

use warnings;

# There's a problem with this perlcritic check
# as of 9 Aug 2010
no warnings qw(recursion qw);

use strict;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '4.001_002';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R3::Internal::Grammar;

use English qw( -no_match_vars );

use Marpa::R3::Thin::Trace;

our %DEFAULT_SYMBOLS_RESERVED;
%DEFAULT_SYMBOLS_RESERVED = map { ($_, 1) } split //xms, '}]>)';

sub Marpa::R3::uncaught_error {
    my ($error) = @_;

    # This would be Carp::confess, but in the testing
    # the stack trace includes the hoped for error
    # message, which causes spurious success reports.
    Carp::croak( "libmarpa reported an error which Marpa::R3 did not catch\n",
        $error );
} ## end sub Marpa::R3::uncaught_error

package Marpa::R3::Internal::Grammar;

sub Marpa::R3::Grammar::g1_naif_new {
    my ( $class, $slg, $flat_args ) = @_;

    my $grammar = [];
    bless $grammar, $class;

    $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS]            = [];
    $grammar->[Marpa::R3::Internal::Grammar::RULES]              = [];
    $grammar->[Marpa::R3::Internal::Grammar::XSY_BY_ISYID] = [];

    $slg->[Marpa::R3::Internal::Scanless::G::G1_RULE_ID_BY_TAG]     = {};

    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C] =
        Marpa::R3::Thin::G->new( { if => 1 } );
    $grammar->[Marpa::R3::Internal::Grammar::TRACER] =
        Marpa::R3::Thin::Trace->new($grammar_c);

    $grammar->g1_naif_set($slg, $flat_args);

    return $grammar;
} ## end sub Marpa::R3::Grammar::new

sub Marpa::R3::Grammar::l0_naif_new {
    my ( $class, $slg, $start_name, $symbols, $rules ) = @_;

    my $grammar = [];
    bless $grammar, $class;

    $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS]            = [];
    $grammar->[Marpa::R3::Internal::Grammar::RULES]              = [];
    $grammar->[Marpa::R3::Internal::Grammar::XSY_BY_ISYID] = [];

    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C] =
        Marpa::R3::Thin::G->new( { if => 1 } );
    $grammar->[Marpa::R3::Internal::Grammar::TRACER] =
        Marpa::R3::Thin::Trace->new($grammar_c);

    for my $symbol ( sort keys %{$symbols} ) {
        my $properties = $symbols->{$symbol};
        assign_symbol( $slg, $grammar, $symbol, $properties );
    }

    $grammar->[Marpa::R3::Internal::Grammar::START_NAME] = $start_name;

    add_user_rules( $slg, $grammar, $rules );

    return $grammar;
} ## end sub Marpa::R3::Grammar::new

sub Marpa::R3::Grammar::tracer {
    return $_[0]->[Marpa::R3::Internal::Grammar::TRACER];
}

sub Marpa::R3::Grammar::thin {
    return $_[0]->[Marpa::R3::Internal::Grammar::C];
}

sub Marpa::R3::Grammar::thin_symbol {
    my ( $grammar, $symbol_name ) = @_;
    return $grammar->[Marpa::R3::Internal::Grammar::TRACER]
        ->symbol_by_name($symbol_name);
}

sub Marpa::R3::Grammar::g1_naif_set {
    my ( $grammar, $slg, $flat_args ) = @_;

    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];

    if ( defined( my $value = $flat_args->{'symbols'} ) ) {
        for my $symbol ( sort keys %{$value} ) {
            my $properties = $value->{$symbol};
            assign_symbol( $slg, $grammar, $symbol, $properties );
        }
        delete $flat_args->{'symbols'};
    } ## end if ( defined( my $value = $flat_args->{'symbols'} ) )

    if ( defined( my $value = $flat_args->{'start'} ) ) {
        $grammar->[Marpa::R3::Internal::Grammar::START_NAME] = $value;
        delete $flat_args->{'start'};
    } ## end if ( defined( my $value = $flat_args->{'start'} ) )

    if ( defined( my $value = $flat_args->{'rules'} ) ) {
        add_user_rules( $slg, $grammar, $value );
        delete $flat_args->{'rules'};
    } ## end if ( defined( my $value = $flat_args->{'rules'} ) )

    my @bad_arguments = keys %{$flat_args};
    if (scalar @bad_arguments) {
        Marpa::R3::exception(
            q{Internal error: Bad named argument(s) to $naif_grammar->set() method}
                . join q{ },
            @bad_arguments
        );
    }

    return 1;
} ## end sub Marpa::R3::Grammar::set

sub Marpa::R3::Grammar::symbol_reserved_set {
    my ( $grammar, $final_character, $boolean ) = @_;
    if ( length $final_character != 1 ) {
        Marpa::R3::exception( 'symbol_reserved_set(): "',
            $final_character, '" is not a symbol' );
    }
    if ( $final_character eq ']' ) {
        return if $boolean;
        Marpa::R3::exception(
            q{symbol_reserved_set(): Attempt to unreserve ']'; this is not allowed}
        );
    } ## end if ( $final_character eq ']' ) ([)
    if ( not exists $DEFAULT_SYMBOLS_RESERVED{$final_character} ) {
        Marpa::R3::exception(
            qq{symbol_reserved_set(): "$final_character" is not a reservable symbol}
        );
    }
    # Return a value to make perlcritic happy
    return $DEFAULT_SYMBOLS_RESERVED{$final_character} = $boolean ? 1 : 0;
} ## end sub Marpa::R3::Grammar::symbol_reserved_set

# Return DSL form of symbol
# Does no checking
sub Marpa::R3::Grammar::symbol_dsl_form {
    my ( $grammar, $slg, $isyid ) = @_;
    my $xsy_by_isyid   = $grammar->[Marpa::R3::Internal::Grammar::XSY_BY_ISYID];
    my $xsy = $xsy_by_isyid->[$isyid];
    return if not defined $xsy;
    return $xsy->[Marpa::R3::Internal::XSY::DSL_FORM];
}

# Return display form of symbol
# Does lots of checking and makes use of alternatives.
sub Marpa::R3::Grammar::symbol_in_display_form {
    my ( $grammar, $slg, $symbol_id ) = @_;
    my $symbols = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    my $symbol  = $symbols->[$symbol_id];
    return "<!No symbol with ID $symbol_id!>" if not defined $symbol;
    my $text = $grammar->symbol_dsl_form( $slg, $symbol_id )
      // $grammar->symbol_name($symbol_id);
    return ( $text =~ m/\s/xms ) ? "<$text>" : $text;
}

sub Marpa::R3::Grammar::show_symbol {
    my ( $grammar, $symbol_id ) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $text      = q{};

    my $name = $grammar->symbol_name($symbol_id);
    $text .= "$symbol_id: $name";

    my @tag_list = ();
    $grammar_c->symbol_is_productive($symbol_id)
        or push @tag_list, 'unproductive';
    $grammar_c->symbol_is_accessible($symbol_id)
        or push @tag_list, 'inaccessible';
    $grammar_c->symbol_is_nulling($symbol_id)  and push @tag_list, 'nulling';
    $grammar_c->symbol_is_terminal($symbol_id) and push @tag_list, 'terminal';

    $text .= join q{ }, q{,}, @tag_list if scalar @tag_list;
    $text .= "\n";
    return $text;

} ## end sub Marpa::R3::Grammar::show_symbol

sub Marpa::R3::Grammar::show_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $text      = q{};
    for my $symbol_id ( 0 .. $grammar_c->highest_symbol_id() ) {
        $text .= $grammar->show_symbol($symbol_id);
    }
    return $text;
} ## end sub Marpa::R3::Grammar::show_symbols

sub Marpa::R3::Grammar::show_nulling_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    return join q{ }, sort map { $grammar->symbol_name($_) }
        grep { $grammar_c->symbol_is_nulling($_) } ( 0 .. $#{$symbols} );
} ## end sub Marpa::R3::Grammar::show_nulling_symbols

sub Marpa::R3::Grammar::show_productive_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    return join q{ }, sort map { $grammar->symbol_name($_) }
        grep { $grammar_c->symbol_is_productive($_) } ( 0 .. $#{$symbols} );
} ## end sub Marpa::R3::Grammar::show_productive_symbols

sub Marpa::R3::Grammar::show_accessible_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    return join q{ }, sort map { $grammar->symbol_name($_) }
        grep { $grammar_c->symbol_is_accessible($_) } ( 0 .. $#{$symbols} );
} ## end sub Marpa::R3::Grammar::show_accessible_symbols

sub Marpa::R3::Grammar::inaccessible_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    return [
        sort map { $grammar->symbol_name($_) }
            grep { !$grammar_c->symbol_is_accessible($_) }
            ( 0 .. $#{$symbols} )
    ];
} ## end sub Marpa::R3::Grammar::inaccessible_symbols

sub Marpa::R3::Grammar::unproductive_symbols {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $symbols   = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    return [
        sort map { $grammar->symbol_name($_) }
            grep { !$grammar_c->symbol_is_productive($_) }
            ( 0 .. $#{$symbols} )
    ];
} ## end sub Marpa::R3::Grammar::unproductive_symbols

sub Marpa::R3::Grammar::start_symbol {
    my ( $grammar ) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    return $grammar_c->start_symbol();
}

sub Marpa::R3::Grammar::rule_name {
    my ( $grammar, $rule_id ) = @_;
    my $rules = $grammar->[Marpa::R3::Internal::Grammar::RULES];
    my $rule  = $rules->[$rule_id];
    return "Non-existent rule $rule_id" if not defined $rule;
    my $name = $rule->[Marpa::R3::Internal::Rule::NAME];
    return $name if defined $name;
    my $tracer    = $grammar->[Marpa::R3::Internal::Grammar::TRACER];
    my ( $lhs_id ) = $tracer->rule_expand($rule_id);
    return $grammar->symbol_name($lhs_id);
} ## end sub Marpa::R3::Grammar::rule_name

# Undocumented -- assumes it is called internally,
# by the SLIF
sub Marpa::R3::Grammar::tag {
    my ( $grammar, $rule_id ) = @_;
    my $rules = $grammar->[Marpa::R3::Internal::Grammar::RULES];
    my $rule  = $rules->[$rule_id];
    return $rule->[Marpa::R3::Internal::Rule::SLIF_TAG];
} ## end sub Marpa::R3::Grammar::rule_name

sub Marpa::R3::Grammar::brief_rule {
    my ( $grammar, $rule_id ) = @_;
    my $symbols   = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R3::Internal::Grammar::TRACER];

    my @symbol_names = ();
    my @symbols = $tracer->rule_expand($rule_id);
    SYMBOL_ID: for my $symbol_id (@symbols) {
        ## The name of the symbols, before the BNF rewrites
        my $name = $grammar->symbol_name($symbol_id);
        push @symbol_names, $name;
    }
    my ( $lhs, @rhs ) = @symbol_names;
    my $minimum = $grammar_c->sequence_min($rule_id);
    my $quantifier = defined $minimum ? $minimum <= 0 ? q{*} : q{+} : q{};
    return ( join q{ }, "$rule_id:", $lhs, '->', @rhs ) . $quantifier;
}

sub Marpa::R3::Grammar::show_rule {
    my ( $grammar, $rule ) = @_;

    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $rule_id   = $rule->[Marpa::R3::Internal::Rule::ID];
    my @comment   = ();

    $grammar_c->rule_length($rule_id) == 0 and push @comment, 'empty';
    $grammar->rule_is_used($rule_id)         or push @comment, '!used';
    $grammar_c->rule_is_productive($rule_id) or push @comment, 'unproductive';
    $grammar_c->rule_is_accessible($rule_id) or push @comment, 'inaccessible';
    $rule->[Marpa::R3::Internal::Rule::DISCARD_SEPARATION]
        and push @comment, 'discard_sep';

    my $text = $grammar->brief_rule($rule_id);

    if (@comment) {
        $text .= q{ } . ( join q{ }, q{/*}, @comment, q{*/} );
    }

    return $text .= "\n";

}    # sub show_rule

sub Marpa::R3::Grammar::show_rules {
    my ($grammar) = @_;
    my $rules = $grammar->[Marpa::R3::Internal::Grammar::RULES];
    my $text;

    for my $rule ( @{$rules} ) {
        $text .= $grammar->show_rule($rule);
    }
    return $text;
} ## end sub Marpa::R3::Grammar::show_rules

# This logic deals with gaps in the rule numbering.
# Currently there are none, but Libmarpa does not
# guarantee this.
sub Marpa::R3::Grammar::rule_ids {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    return 0 .. $grammar_c->highest_rule_id();
} ## end sub Marpa::R3::Grammar::rule_ids

# This logic deals with gaps in the symbol numbering.
# Currently there are none, but Libmarpa does not
# guarantee this.
sub Marpa::R3::Grammar::symbol_ids {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    return 0 .. $grammar_c->highest_symbol_id();
} ## end sub Marpa::R3::Grammar::rule_ids

# Internal, for use with in coordinating thin and thick
# interfaces.  NOT DOCUMENTED.
sub Marpa::R3::Grammar::_rule_mask {
    my ( $grammar, $rule_id ) = @_;
    my $rules = $grammar->[Marpa::R3::Internal::Grammar::RULES];
    my $rule = $rules->[$rule_id];
    return $rule->[Marpa::R3::Internal::Rule::MASK];
} ## end sub Marpa::R3::Grammar::rule

sub Marpa::R3::Grammar::show_dotted_rule {
    my ( $grammar, $rule_id, $dot_position ) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my ( $lhs, @rhs ) = $grammar->rule($rule_id);

    my $minimum = $grammar_c->sequence_min($rule_id);
    if (defined $minimum) {
        my $quantifier = $minimum <= 0 ? q{*} : q{+} ;
        $rhs[0] .= $quantifier;
    }
    $dot_position = 0 if $dot_position < 0;
    splice @rhs, $dot_position, 0, q{.};
    return join q{ }, $lhs, q{->}, @rhs;
} ## end sub Marpa::R3::Grammar::show_dotted_rule

sub Marpa::R3::Grammar::symbol_name {
    my ( $grammar, $id ) = @_;
    my $symbol_name =
        $grammar->[Marpa::R3::Internal::Grammar::TRACER]->symbol_name($id);
    return defined $symbol_name ? $symbol_name : '[SYMBOL#' . $id . ']';
} ## end sub Marpa::R3::Grammar::symbol_name

# Create the structure which "shadows" the libmarpa rule
sub shadow_rule {
    my ( $grammar, $rule_id ) = @_;
    my $rules = $grammar->[Marpa::R3::Internal::Grammar::RULES];
    my $new_rule = $rules->[$rule_id] = [];
    $new_rule->[Marpa::R3::Internal::Rule::ID] = $rule_id;
    return $new_rule;
} ## end sub shadow_rule

sub assign_symbol {
    # $slg will be needed for the XSY's
    my ( $slg, $grammar, $name, $options ) = @_;

    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R3::Internal::Grammar::TRACER];
    my $symbols = $grammar->[Marpa::R3::Internal::Grammar::SYMBOLS];
    my $symbol_id = $tracer->symbol_by_name($name);
    if ( defined $symbol_id ) {
        return $symbols->[$symbol_id];
    }
    $symbol_id = $tracer->symbol_new($name);
    my $symbol = $symbols->[$symbol_id] = [];
    $symbol->[Marpa::R3::Internal::Symbol::ISYID] = $symbol_id;

    PROPERTY: for my $property ( sort keys %{$options} ) {
        if ( $property eq 'wsyid' ) {
            next PROPERTY;
        }
        if ( $property eq 'xsy' ) {
            my $xsy_name = $options->{$property};
            my $xsy = $slg->[Marpa::R3::Internal::Scanless::G::XSY_BY_NAME]->{$xsy_name};
            $grammar->[Marpa::R3::Internal::Grammar::XSY_BY_ISYID]->[$symbol_id] =
                $xsy;
            next PROPERTY;
        }
        if ( $property eq 'terminal' ) {
            my $value = $options->{$property};
            $grammar_c->symbol_is_terminal_set( $symbol_id, $value );
            next PROPERTY;
        }
        if ( $property eq 'rank' ) {
            my $value = $options->{$property};
            Marpa::R3::exception(qq{Symbol "$name": rank must be an integer})
                if not Scalar::Util::looks_like_number($value)
                    or int($value) != $value;
            $grammar_c->symbol_rank_set($symbol_id) = $value;
            next PROPERTY;
        } ## end if ( $property eq 'rank' )
        Marpa::R3::exception(qq{Unknown symbol property "$property"});
    } ## end PROPERTY: for my $property ( keys %{$options} )

    return $symbol;

} ## end sub assign_symbol

# add one or more rules
sub add_user_rules {
    my ( $slg, $grammar, $rules ) = @_;

    for my $rule (@{$rules}) {
        add_user_rule( $slg, $grammar, $rule );
    }

    return;

} ## end sub add_user_rules

sub add_user_rule {
    my ( $slg, $grammar, $options ) = @_;

    Marpa::R3::exception('Missing argument to add_user_rule')
        if not defined $grammar
        or not defined $options;

    my $grammar_c    = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $tracer       = $grammar->[Marpa::R3::Internal::Grammar::TRACER];
    my $rules        = $grammar->[Marpa::R3::Internal::Grammar::RULES];
    my $default_rank = $grammar_c->default_rank();

    my ( $lhs_name, $rhs_names, $action, $blessing );
    my ( $min, $separator_name );
    my $rank;
    my $null_ranking;
    my $rule_name;
    my $slif_tag;
    my $mask;
    my $proper_separation = 0;
    my $keep_separation   = 0;

  OPTION: for my $option ( keys %{$options} ) {
        my $value = $options->{$option};
        if ( $option eq 'name' )   { $rule_name = $value; next OPTION; }
        if ( $option eq 'tag' )    { $slif_tag  = $value; next OPTION; }
        if ( $option eq 'rhs' )    { $rhs_names = $value; next OPTION }
        if ( $option eq 'lhs' )    { $lhs_name  = $value; next OPTION }
        if ( $option eq 'action' ) { $action    = $value; next OPTION }
        if ( $option eq 'bless' )  { $blessing  = $value; next OPTION }
        if ( $option eq 'rank' )   { $rank      = $value; next OPTION }
        if ( $option eq 'null_ranking' ) {
            $null_ranking = $value;
            next OPTION;
        }
        if ( $option eq 'min' ) { $min = $value; next OPTION }
        if ( $option eq 'separator' ) {
            $separator_name = $value;
            next OPTION;
        }
        if ( $option eq 'proper' ) {
            $proper_separation = $value;
            next OPTION;
        }
        if ( $option eq 'keep' ) { $keep_separation = $value; next OPTION }
        if ( $option eq 'mask' ) { $mask            = $value; next OPTION }
        if ( $option eq 'description' ) {

            # TODO: Delete this once description field eliminated
            next OPTION;
        }
        Marpa::R3::exception("Unknown user rule option: $option");
    } ## end OPTION: for my $option ( keys %{$options} )

    if ( defined $min and not Scalar::Util::looks_like_number($min) ) {
        Marpa::R3::exception(
            q{"min" must be undefined or a valid Perl number});
    }

    my $lhs = assign_symbol( $slg, $grammar, $lhs_name );
    $rhs_names //= [];

    my @rule_problems = ();

    my $rhs_ref_type = ref $rhs_names;
    if ( not $rhs_ref_type or $rhs_ref_type ne 'ARRAY' ) {
        my $problem =
              "RHS is not ref to ARRAY\n"
            . '  Type of rhs is '
            . ( $rhs_ref_type ? $rhs_ref_type : 'not a ref' ) . "\n";
        my $d = Data::Dumper->new( [$rhs_names], ['rhs'] );
        $problem .= $d->Dump();
        push @rule_problems, $problem;
    } ## end if ( not $rhs_ref_type or $rhs_ref_type ne 'ARRAY' )
    if ( not defined $lhs_name ) {
        push @rule_problems, "Missing LHS\n";
    }

    if ( defined $rank
        and
        ( not Scalar::Util::looks_like_number($rank) or int($rank) != $rank )
        )
    {
        push @rule_problems, "Rank must be undefined or an integer\n";
    } ## end if ( defined $rank and ( not Scalar::Util::looks_like_number...))
    $rank //= $default_rank;

    $null_ranking //= 'low';
    if ( $null_ranking ne 'high' and $null_ranking ne 'low' ) {
        push @rule_problems,
            "Null Ranking must be undefined, 'high' or 'low'\n";
    }

    if ( scalar @rule_problems ) {
        my %dump_options = %{$options};
        delete $dump_options{grammar};
        my $msg = ( scalar @rule_problems )
            . " problem(s) in the following rule:\n";
        my $d = Data::Dumper->new( [ \%dump_options ], ['rule'] );
        $msg .= $d->Dump();
        for my $problem_number ( 0 .. $#rule_problems ) {
            $msg
                .= 'Problem '
                . ( $problem_number + 1 ) . q{: }
                . $rule_problems[$problem_number] . "\n";
        } ## end for my $problem_number ( 0 .. $#rule_problems )
        Marpa::R3::exception($msg);
    } ## end if ( scalar @rule_problems )

    my $rhs = [
        map {
                assign_symbol( $slg, $grammar, $_ )
        } @{$rhs_names}
    ];

    # Is this is an ordinary, non-counted rule?
    my $is_ordinary_rule = scalar @{$rhs_names} == 0 || !defined $min;
    if ( defined $separator_name and $is_ordinary_rule ) {
        if ( defined $separator_name ) {
            Marpa::R3::exception(
                'separator defined for rule without repetitions');
        }
    } ## end if ( defined $separator_name and $is_ordinary_rule )

    my @rhs_ids = map { $_->[Marpa::R3::Internal::Symbol::ISYID] } @{$rhs};
    my $lhs_id = $lhs->[Marpa::R3::Internal::Symbol::ISYID];

    my $base_rule_id;
    my $separator_id = -1;

    if ($is_ordinary_rule) {

        # Capture errors
        $grammar_c->throw_set(0);
        $base_rule_id = $grammar_c->rule_new( $lhs_id, \@rhs_ids );
        $grammar_c->throw_set(1);

    } ## end if ($is_ordinary_rule)
    else {
        Marpa::R3::exception('Only one rhs symbol allowed for counted rule')
            if scalar @{$rhs_names} != 1;

        # create the separator symbol, if we're using one
        if ( defined $separator_name ) {
            my $separator = assign_symbol( $slg, $grammar, $separator_name ) ;
            $separator_id = $separator->[Marpa::R3::Internal::Symbol::ISYID];
        } ## end if ( defined $separator_name )

        $grammar_c->throw_set(0);

        # The original rule for a sequence rule is
        # not actually used in parsing,
        # but some of the rewritten sequence rules are its
        # semantic equivalents.

        $base_rule_id = $grammar_c->sequence_new(
            $lhs_id,
            $rhs_ids[0],
            {   separator => $separator_id,
                proper    => $proper_separation,
                min       => $min,
            }
        );
        $grammar_c->throw_set(1);
    } ## end else [ if ($is_ordinary_rule) ]

    if ( not defined $base_rule_id or $base_rule_id < 0 ) {
        my $rule_description = rule_describe( $lhs_name, $rhs_names );
        my ( $error_code, $error_string ) = $grammar_c->error();
        $error_code //= -1;
        my $problem_description =
            $error_code == $Marpa::R3::Error::DUPLICATE_RULE
            ? 'Duplicate rule'
            : $error_string;
        Marpa::R3::exception("$problem_description: $rule_description");
    } ## end if ( not defined $base_rule_id or $base_rule_id < 0 )

    my $base_rule = shadow_rule( $grammar, $base_rule_id );

    if ($is_ordinary_rule) {

        # Only internal grammars can set a custom mask
        if ( not defined $mask ) {
            $mask = [ (1) x scalar @rhs_ids ];
        }
        $base_rule->[Marpa::R3::Internal::Rule::MASK] = $mask;
    } ## end if ($is_ordinary_rule)

    $base_rule->[Marpa::R3::Internal::Rule::DISCARD_SEPARATION] =
        $separator_id >= 0 && !$keep_separation;

    $base_rule->[Marpa::R3::Internal::Rule::ACTION_NAME] = $action;
    $grammar_c->rule_null_high_set( $base_rule_id,
        ( $null_ranking eq 'high' ? 1 : 0 ) );
    $grammar_c->rule_rank_set( $base_rule_id, $rank );

    if ( defined $rule_name ) {
        $base_rule->[Marpa::R3::Internal::Rule::NAME] = $rule_name;
    }
    if ( defined $slif_tag ) {
        $base_rule->[Marpa::R3::Internal::Rule::SLIF_TAG] = $slif_tag;
        my $rule_id_by_tag =
            $slg->[Marpa::R3::Internal::Scanless::G::G1_RULE_ID_BY_TAG];
        if ( $rule_id_by_tag->{$slif_tag} ) {
            Marpa::R3::exception(
                qq{Duplicate tag in SLIF rule, tag was "$slif_tag"});
        }
        $rule_id_by_tag->{$slif_tag} = $base_rule_id;
    } ## end if ( defined $slif_tag )
    if ( defined $blessing ) {
        $base_rule->[Marpa::R3::Internal::Rule::BLESSING] = $blessing;
    }

    return;

}

sub rule_describe {
    my ( $lhs_name, $rhs_names ) = @_;
    # wrap symbol names with whitespaces allowed by SLIF
    $lhs_name = "<$lhs_name>" if $lhs_name =~ / /;
    return "$lhs_name -> " . ( join q{ }, map { / / ? "<$_>" : $_ } @{$rhs_names} );
} ## end sub rule_describe

sub Marpa::R3::Grammar::error {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    return $grammar_c->error();
}

# INTERNAL OK AFTER HERE _marpa_

sub Marpa::R3::Grammar::show_isy {
    my ( $grammar, $isy_id ) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R3::Internal::Grammar::TRACER];
    my $text      = q{};

    my $name = $tracer->isy_name($isy_id);
    $text .= "$isy_id: $name";

    my @tag_list = ();
    $grammar_c->_marpa_g_nsy_is_nulling($isy_id)
        and push @tag_list, 'nulling';

    $text .= join q{ }, q{,}, @tag_list if scalar @tag_list;
    $text .= "\n";

    return $text;

} ## end sub Marpa::R3::Grammar::show_isy

sub Marpa::R3::Grammar::show_isys {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $text      = q{};
    for my $isy_id ( 0 .. $grammar_c->_marpa_g_nsy_count() - 1 ) {
        $text .= $grammar->show_isy($isy_id);
    }
    return $text;
} ## end sub Marpa::R3::Grammar::show_isys

sub Marpa::R3::Grammar::brief_irl {
    my ( $grammar, $irl_id ) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $tracer    = $grammar->[Marpa::R3::Internal::Grammar::TRACER];
    my $lhs_id    = $grammar_c->_marpa_g_irl_lhs($irl_id);
    my $text = $irl_id . ': ' . $tracer->isy_name($lhs_id) . ' ->';
    if ( my $rh_length = $grammar_c->_marpa_g_irl_length($irl_id) ) {
        my @rhs_ids = ();
        for my $ix ( 0 .. $rh_length - 1 ) {
            push @rhs_ids, $grammar_c->_marpa_g_irl_rhs( $irl_id, $ix );
        }
        $text .= q{ } . ( join q{ }, map { $tracer->isy_name($_) } @rhs_ids );
    } ## end if ( my $rh_length = $grammar_c->_marpa_g_irl_length...)
    return $text;
} ## end sub Marpa::R3::Grammar::brief_irl

sub Marpa::R3::Grammar::show_irls {
    my ($grammar) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    my $text      = q{};
    for my $irl_id ( 0 .. $grammar_c->_marpa_g_irl_count() - 1 ) {
        $text .= $grammar->brief_irl($irl_id) . "\n";
    }
    return $text;
} ## end sub Marpa::R3::Grammar::show_irls

sub Marpa::R3::Grammar::rule_is_used {
    my ( $grammar, $rule_id ) = @_;
    my $grammar_c = $grammar->[Marpa::R3::Internal::Grammar::C];
    return $grammar_c->_marpa_g_rule_is_used($rule_id);
}

sub Marpa::R3::Grammar::show_ahms {
    my ( $grammar, $verbose ) = @_;
    return $grammar->[Marpa::R3::Internal::Grammar::TRACER]
        ->show_ahms($verbose);
}

1;

# vim: expandtab shiftwidth=4:
