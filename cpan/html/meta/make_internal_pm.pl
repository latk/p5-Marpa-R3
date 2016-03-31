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

use 5.010;
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
# Copyright 2015 Jeffrey Kegler
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

# DO NOT EDIT THIS FILE DIRECTLY
# It was generated by !!!PROGRAM_NAME!!!

package Marpa::R3::Internal;

use 5.010;
use strict;
use warnings;
use Carp;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '3.001_000';
$STRING_VERSION = $VERSION;
$VERSION = eval $VERSION;
END_OF_HEADER

}

__DATA__

    :package=Marpa::R3::HTML::Internal::TDesc
    TYPE
    START_TOKEN
    END_TOKEN
    VALUE
    RULE_ID
 
    :package=Marpa::R3::HTML::Internal::Token
    TOKEN_ID
    =TAG_NAME
    TYPE
    LINE
    COL
    =COLUMN
    START_OFFSET
    END_OFFSET
    IS_CDATA
    ATTR
