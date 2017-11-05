# Copyright 2017 Jeffrey Kegler
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

# DO NOT EDIT THIS FILE DIRECTLY
# It was generated by !!!PROGRAM_NAME!!!

package Marpa::R3::Internal;

use 5.010001;
use strict;
use warnings;
use Carp;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '4.001_050';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;
END_OF_HEADER

}

__DATA__

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
    SLV { The underlying SLV }
    END_OF_PARSE

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

    :package=Marpa::R3::Internal_G

    L { Lua Interpreter }
    REGIX { Registry index in Lua interpreter --
        a valid Lua index but not a pseudo-index. }

    TRACE_FILE_HANDLE
    CONSTANTS
    CHARACTER_CLASS_TABLE

    { TODO -- Convert fields after here to Lua? }

    BLESS_PACKAGE { Default package into which nodes are blessed }
    IF_INACCESSIBLE { default for symbols }

    CHARACTER_CLASSES { an hash of
    character class regex by symbol name.
    Used before precomputation. }

    { Semantics }
    SEMANTICS_PACKAGE
    TRACE_ACTIONS

    NULL_VALUES
    CLOSURE_BY_SYMBOL_ID
    CLOSURE_BY_RULE_ID

    :package=Marpa::R3::Internal_R

    SLG

    L { Lua Interpreter }
    REGIX { Registry index in Lua interpreter --
        a valid Lua index but not a pseudo-index. }

    TRACE_FILE_HANDLE
    EVENT_HANDLERS { Application-level event handlers }
    CURRENT_EVENT

    :package=Marpa::R3::Internal_V

    SLR

    L { Lua Interpreter }
    REGIX { Registry index in Lua interpreter --
        a valid Lua index but not a pseudo-index. }

    TRACE_FILE_HANDLE

    { vim: set expandtab shiftwidth=4:
    }
