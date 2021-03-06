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

# Test using a JSON parser
# Inspired by a parser written by Peter Stuifzand

use 5.010001;

use strict;
use warnings;
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale(LC_ALL, "C");

use Test::More tests => 15;

## no critic (ErrorHandling::RequireCarping);

use Marpa::R3;

my $p = MarpaX::JSON->new;

my $data = $p->parse_json(q${"test":"1"}$);
is($data->{test}, 1);

{
    my $test = q${"test":[1,2,3]}$;
    $data = $p->parse_json(q${"test":[1,2,3]}$);
    is_deeply( $data->{test}, [ 1, 2, 3 ], $test );
}

$data = $p->parse_json(q${"test":true}$);
is($data->{test}, 1);

$data = $p->parse_json(q${"test":false}$);
is($data->{test}, '');

$data = $p->parse_json(q${"test":null}$);
is($data->{test}, undef);

$data = $p->parse_json(q${"test":null, "test2":"hello world"}$);
is($data->{test}, undef);
is($data->{test2}, "hello world");

$data = $p->parse_json(q${"test":"1.25"}$);
is($data->{test}, '1.25', '1.25');

$data = $p->parse_json(q${"test":"1.25e4"}$);
is($data->{test}, '1.25e4', '1.25e4');

$data = $p->parse_json(q$[]$);
is_deeply($data, [], '[]');

$data = $p->parse_json(q${}$);
is_deeply($data, {}, '{}');

$data = $p->parse_json(<<'JSON');
[
      {
         "precision": "zip",
         "Latitude":  37.7668,
         "Longitude": -122.3959,
         "Address":   "",
         "City":      "SAN FRANCISCO",
         "State":     "CA",
         "Zip":       "94107",
         "Country":   "US"
      },
      {
         "precision": "zip",
         "Latitude":  37.371991,
         "Longitude": -122.026020,
         "Address":   "",
         "City":      "SUNNYVALE",
         "State":     "CA",
         "Zip":       "94085",
         "Country":   "US"
      }
]
JSON
is_deeply($data, [
    { "precision"=>"zip", Latitude => "37.7668", Longitude=>"-122.3959",
      "Country" => "US", Zip => 94107, Address => '',
      City => "SAN FRANCISCO", State => 'CA' },
    { "precision" => "zip", Longitude => "-122.026020", Address => "",
      City => "SUNNYVALE", Country => "US", Latitude => "37.371991",
      Zip => 94085, State => "CA" }
], 'Geo data');

$data = $p->parse_json(<<'JSON');
{
    "Image": {
        "Width":  800,
        "Height": 600,
        "Title":  "View from 15th Floor",
        "Thumbnail": {
            "Url":    "http://www.example.com/image/481989943",
            "Height": 125,
            "Width":  "100"
        },
        "IDs": [116, 943, 234, 38793]
    }
}
JSON
is_deeply($data, { 
    "Image" => {
        "Width" => 800, "Height" => 600,
        "Title" => "View from 15th Floor",
        "Thumbnail" => {
            "Url" => "http://www.example.com/image/481989943",
            "Height" => 125,
            "Width" => 100,
        },
        "IDs" => [ 116, 943, 234, 38793 ],
    }
}, 'is_deeply test');

my $big_test = <<'JSON';
{
    "source" : "<a href=\"http://janetter.net/\" rel=\"nofollow\">Janetter</a>",
    "entities" : {
        "user_mentions" : [ {
                "name" : "James Governor",
                "screen_name" : "moankchips",
                "indices" : [ 0, 10 ],
                "id_str" : "61233",
                "id" : 61233
            } ],
        "media" : [ ],
        "hashtags" : [ ],
        "urls" : [ ]
    },
    "in_reply_to_status_id_str" : "281400879465238529",
    "geo" : {
    },
    "id_str" : "281405942321532929",
    "in_reply_to_user_id" : 61233,
    "text" : "@monkchips Ouch. Some regrets are harsher than others.",
    "id" : 281405942321532929,
    "in_reply_to_status_id" : 281400879465238529,
    "created_at" : "Wed Dec 19 14:29:39 +0000 2012",
    "in_reply_to_screen_name" : "monkchips",
    "in_reply_to_user_id_str" : "61233",
    "user" : {
        "name" : "Sarah Bourne",
        "screen_name" : "sarahebourne",
        "protected" : false,
        "id_str" : "16010789",
        "profile_image_url_https" : "https://si0.twimg.com/profile_images/638441870/Snapshot-of-sb_normal.jpg",
        "id" : 16010789,
        "verified" : false
    }
}
JSON
$data = $p->parse_json($big_test);

is_deeply $data, eval q{
{
  'source' => '<a href="http://janetter.net/" rel="nofollow">Janetter</a>',
  'geo' => {},
  'in_reply_to_user_id_str' => '61233',
  'id_str' => '281405942321532929',
  'entities' => {
                  'hashtags' => [],
                  'media' => [],
                  'user_mentions' => [
                                       {
                                         'name' => 'James Governor',
                                         'id' => '61233',
                                         'id_str' => '61233',
                                         'indices' => [
                                                        '0',
                                                        '10'
                                                      ],
                                         'screen_name' => 'moankchips'
                                       }
                                     ],
                  'urls' => []
                },
  'created_at' => 'Wed Dec 19 14:29:39 +0000 2012',
  'in_reply_to_status_id_str' => '281400879465238529',
  'text' => '@monkchips Ouch. Some regrets are harsher than others.',
  'user' => {
              'protected' => '',
              'name' => 'Sarah Bourne',
              'verified' => '',
              'id' => '16010789',
              'id_str' => '16010789',
              'profile_image_url_https' => 'https://si0.twimg.com/profile_images/638441870/Snapshot-of-sb_normal.jpg',
              'screen_name' => 'sarahebourne'
            },
  'in_reply_to_user_id' => '61233',
  'id' => '281405942321532929',
  'in_reply_to_status_id' => '281400879465238529',
  'in_reply_to_screen_name' => 'monkchips'
}  
}, "big test";

$data = $p->parse_json(<<'JSON');
{ "test":  "\u2603" }
JSON
is($data->{test}, "\x{2603}", 'Unicode char');

package MarpaX::JSON;

sub new {

    my ($class) = @_;

    my $parser = bless {}, $class;
    
    $parser->{grammar} = Marpa::R3::Grammar->new(
        {
            source         => \(<<'END_OF_SOURCE'),

            :default     ::= action => [name, value]
            lexeme default = action => [name, value]

            json         ::= object 
                           | array

            object       ::= ('{' '}')
                           | ('{') members ('}')

            members      ::= pair*                  separator => [,]

            pair         ::= string (':') value

            value        ::= string
                           | object
                           | number
                           | array
                           | 'true' 
                           | 'false'
                           | 'null' 


            array        ::= ('[' ']')
                           | ('[') elements (']') 

            elements     ::= value+                 separator => [,]

            number         ~ int
                           | int frac
                           | int exp
                           | int frac exp

            int            ~ digits
                           | '-' digits

            digits         ~ [\d]+

            frac           ~ '.' digits

            exp            ~ e digits

            e              ~ 'e'
                           | 'e+'
                           | 'e-'
                           | 'E'
                           | 'E+'
                           | 'E-'

            string       ::= lstring

            lstring        ~ quote in_string quote
            quote          ~ ["]
            in_string      ~ in_string_char*
            in_string_char ~ [^"] | '\"'

            :discard       ~ whitespace
            whitespace     ~ [\s]+

END_OF_SOURCE
        }
    );

    return $parser;
}

sub parse {
    my ( $parser, $string ) = @_;

    my $recce =
      Marpa::R3::Recognizer->new( { grammar => $parser->{grammar}, } );
    $recce->read( \$string );
    my $valuer = Marpa::R3::Valuer->new( { recognizer => $recce } );
    my $ast = ${ $valuer->value() };
    return $parser->decode($ast);
}

sub decode {
    my $parser = shift;
    
    my $ast  = shift;
    
    if (ref $ast){
        my ($id, @nodes) = @$ast;
        if ($id eq 'json'){
            $parser->decode(@nodes);
        }
        elsif ($id eq 'members'){
            return { map { $parser->decode($_) } @nodes }; 
        }
        elsif ($id eq 'pair'){
            return map { $parser->decode($_) } @nodes; 
        }
        elsif ($id eq 'elements'){
            return [ map { $parser->decode($_) } @nodes ]; 
        }
        elsif ($id eq 'string'){
            return decode_string( substr $nodes[0]->[1], 1, -1 );
        }
        elsif ($id eq 'number'){
            return $nodes[0];
        }
        elsif ($id eq 'object'){
            return {} unless @nodes;
            return $parser->decode($_) for @nodes; 
        }
        elsif ($id eq 'array'){
            return [] unless @nodes;
            return $parser->decode($_) for @nodes; 
        }
        else{
            return $parser->decode($_) for @nodes; 
        }
    }
    else
    {
        if ($ast eq 'true' or $ast eq 'false'){ return $ast eq 'true' }
        elsif ($ast eq 'null' ){ return undef }
        else { warn "unknown scalar <$ast>"; return $ast }
    }
}

sub parse_json {
    my ($parser, $string) = @_;
    return $parser->parse($string);
}

sub decode_string {
    my ($s) = @_;
    
    $s =~ s/\\u([0-9A-Fa-f]{4})/chr(hex($1))/egxms;
    $s =~ s/\\n/\n/gxms;
    $s =~ s/\\r/\r/gxms;
    $s =~ s/\\b/\b/gxms;
    $s =~ s/\\f/\f/gxms;
    $s =~ s/\\t/\t/gxms;
    $s =~ s/\\\\/\\/gxms;
    $s =~ s{\\/}{/}gxms;
    $s =~ s{\\"}{"}gxms;

    return $s;
} ## end sub decode_string

# vim: expandtab shiftwidth=4:
