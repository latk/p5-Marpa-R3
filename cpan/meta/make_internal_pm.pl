# Copyright 2016 Jeffrey Kegler
# Marpa::R3 is Copyright (C) 2016, Jeffrey Kegler.
#
# This module is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.10.1. For more details, see the full text
# of the licenses in the directory LICENSES.
#
# This program is distributed in the hope that it will be
# useful, but it is provided “as is” and without any express
# or implied warranties. For details, see the full text of
# of the licenses in the directory LICENSES.

use 5.010001;
use strict;
use warnings;
use Carp;
use English qw( -no_match_vars );

our $HEADER;

sub offset {
    my ($desc) = @_;
    my @fields = split q{ }, $desc;
    my $offset     = -1;
    my $in_comment = 0;

    no strict 'refs';
    FIELD: for my $field (@fields) {

        if ($in_comment) {
            $in_comment = $field ne ':}' && $field ne '}';
            next FIELD;
        }

        PROCESS_OPTION: {
            last PROCESS_OPTION if $field !~ /\A [{:] /xms;
            if ( $field =~ / \A [:] package [=] (.*) /xms ) {
                say "\npackage $1;";
                $offset = -1;
                next FIELD;
            }
            if ( $field =~ / \A [:]? [{] /xms ) {
                $in_comment++;
                next FIELD;
            }
        } ## end PROCESS_OPTION:


        if ((substr $field, 0, 1) eq '=') {
            $field = substr $field, 1;
        } else {
            $offset++;
        }
        die "Unacceptable field name: $field"
              if $field =~ /[^A-Z0-9_]/xms;
        say "use constant $field => $offset;"

    } ## end for my $field (@fields)
    return 1;
} ## end sub Marpa::R3::offset

$HEADER =~ s/!!!PROGRAM_NAME!!!/$PROGRAM_NAME/;
say $HEADER;
$RS = undef;
offset(<DATA>);
say "\n1;";

BEGIN {

$HEADER = <<'END_OF_HEADER';
# Marpa::R3 is Copyright (C) 2016, Jeffrey Kegler.
#
# This module is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.10.1. For more details, see the full text
# of the licenses in the directory LICENSES.
#
# This program is distributed in the hope that it will be
# useful, but it is provided “as is” and without any express
# or implied warranties. For details, see the full text of
# of the licenses in the directory LICENSES.

# DO NOT EDIT THIS FILE DIRECTLY
# It was generated by !!!PROGRAM_NAME!!!

package Marpa::R3::Internal;

use 5.010001;
use strict;
use warnings;
use Carp;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '4.001_024';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;
END_OF_HEADER

}

__DATA__

    :package=Marpa::R3::Internal::XSY
    ID
    NAME
    NAME_SOURCE { Where is the symbol name from?
       lexical?  internal?
    }
    BLESSING
    LEXEME_SEMANTICS
    DSL_FORM
    IF_INACCESSIBLE

    :package=Marpa::R3::Internal::XRL

    ID
    NAME
    LHS
    START
    LENGTH
    PRECEDENCE_COUNT

    :package=Marpa::R3::Internal::XBNF

    ID
    NAME
    START
    LENGTH
    LHS
    RHS
    RANK
    NULL_RANKING
    MIN
    SEPARATOR
    PROPER
    DISCARD_SEPARATION
    MASK { Semantic mask of RHS symbols }
    ACTION_NAME
    BLESSING
    SYMBOL_AS_EVENT
    EVENT
    XRL

    :package=Marpa::R3::Internal::Trace::G

    NAME { Name of the grammar -- 'L0' or 'G1' }

    C { A C structure }
    NAME_BY_ISYID
    ISYID_BY_NAME
    XSY_BY_ISYID { Array mapping ISYID to XSY }
    XBNF_BY_IRLID { Array mapping IRLID to XBNF }
    ACTION_BY_IRLID
    MASK_BY_IRLID
    START_NAME

    :package=Marpa::R3::Internal::Progress_Report

    RULE_ID
    POSITION
    ORIGIN
    CURRENT

    :package=Marpa::R3::Internal::Glade

    ID
    SYMCHES
    VISITED
    REGISTERED

    :package=Marpa::R3::Internal::Choicepoint

    { An external choicepoint }
    ASF
    FACTORING_STACK
    OR_NODE_IN_USE

    :package=Marpa::R3::Internal::Nook

    PARENT
    OR_NODE
    FIRST_CHOICE
    LAST_CHOICE
    IS_CAUSE
    IS_PREDECESSOR
    CAUSE_IS_EXPANDED
    PREDECESSOR_IS_EXPANDED

    :package=Marpa::R3::Internal::ASF

    { It is important not to keep any references to choicepoints, direct or
      indirect in this structure.  The resulting circular reference would prevent
      both structures from being freed, and create a memory leak. }

    SLR { The underlying SLR }
    LEXEME_RESOLUTIONS
    RULE_RESOLUTIONS

    FACTORING_MAX
    RULE_BLESSINGS
    SYMBOL_BLESSINGS

    SYMCH_BLESSING_PACKAGE
    FACTORING_BLESSING_PACKAGE
    PROBLEM_BLESSING_PACKAGE
    DEFAULT_RULE_BLESSING_PACKAGE
    DEFAULT_TOKEN_BLESSING_PACKAGE

    OR_NODES {
        per or-node data, 
        current arrays of sorted and-nodes
    }
    GLADES { Memoized forest }

    INTSET_BY_KEY
    NEXT_INTSET_ID

    { use powersets for choicepoints only
      -- create a new series if I need them for something else
    }
    NIDSET_BY_ID
    POWERSET_BY_ID

    :package=Marpa::R3::Internal::ASF::Traverse

    ASF
    VALUES { Memoized values, by glade ID }
    CODE { The anonymous subtroutine for traversal }
    PER_TRAVERSE_OBJECT { a "scratch" object for the traversal }
    GLADE
    SYMCH_IX
    FACTORING_IX

    :package=Marpa::R3::Internal::Nidset

    ID
    NIDS

    :package=Marpa::R3::Internal::Powerset

    ID
    NIDSET_IDS

    :package=Marpa::R3::Internal::Scanless::G

    C { The thin version of this object }

    { The "tracers", are objects
       which wrap the "thin" C structure.  }
    L0_TRACER
    G1_TRACER

    CHARACTER_CLASS_TABLE
    DISCARD_EVENT_BY_LEXER_RULE

    XSY_BY_ID { eXternal symbols, by XSYID }
    XSY_BY_NAME { eXternal symbols, by XSY name }
    L0_XBNF_BY_ID { L0 eXternal SEQuence, by XBNFID }
    G1_XBNF_BY_ID { G1 eXternal SEQuence, by XBNFID }
    L0_XBNF_BY_NAME { L0 eXternal SEQuence, by XBNF name }
    G1_XBNF_BY_NAME { G1 eXternal SEQuence, by XBNF name }
    XRL_BY_ID { G1 eXternal RuLe, by XRLID }
    XRL_BY_NAME { L0 eXternal RuLe, by XRL name }
    COMPLETION_EVENT_BY_ID
    NULLED_EVENT_BY_ID
    PREDICTION_EVENT_BY_ID
    LEXEME_EVENT_BY_ID
    SYMBOL_IDS_BY_EVENT_NAME_AND_TYPE

    { This saves a lot of time at points }
    CACHE_G1_IRLIDS_BY_LHS_NAME

    BLESS_PACKAGE { Default package into which nodes are blessed }
    IF_INACCESSIBLE { default for symbols }

    WARNINGS { print warnings about grammar? }
    TRACE_FILE_HANDLE
    TRACE_TERMINALS

    CHARACTER_CLASSES { an hash of
    character class regex by symbol name.
    Used before precomputation. }

    :package=Marpa::R3::Internal::Scanless::R

    SLG

    { "Thin" interfaces,
      that is, objects for the C language Perl/XS
      interfaces
    }
    SLR_C { The thin version of this object }
    R_C { The thin version of the G1 recognizer }

    P_INPUT_STRING

    EXHAUSTION_ACTION
    REJECTION_ACTION
    TRACE_FILE_HANDLE
    TRACE_LEXERS
    TRACE_TERMINALS
    TRACE_VALUES
    TRACE_ACTIONS
    READ_STRING_ERROR
    EVENTS

    ERROR_MESSAGE { Temporary place to put an error message for later use.
    One use is when the error occurs in a subroutine, but you want the bail message
    to have the benefit of a higher-level context.
    }

    MAX_PARSES
    RANKING_METHOD

    { The following fields must be reinitialized when
    evaluation is reset }

    NO_PARSE { no parse found in parse series -- memoized }
    NULL_VALUES
    TREE_MODE { 'tree' or 'forest' or undef }
    END_OF_PARSE

    { Fields for new SLIF resolution logic
    -- must be reinitialized when evaluation is reset }
    SEMANTICS_PACKAGE
    REGISTRATIONS
    CLOSURE_BY_SYMBOL_ID
    CLOSURE_BY_RULE_ID

    { This is the end of the list of fields which
    must be reinitialized when evaluation is reset }

    { vim: set expandtab shiftwidth=4:
    }
