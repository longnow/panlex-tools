#!/usr/bin/env perl
use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use Unicode::Normalize;

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

my %MAP = (
    ' '     => ' ',
    "\n"    => "\n",
    '&'     => '’',
    '∫'     => "'",
    'à'     => '©',
    'ä'     => '«',
    'ô'     => '»',
    'ø'     => 'ɛ',
    'Õ'     => 'i',
    'À'     => 'ɨ',
    '≠'     => 'ɨ',
    '—'     => 'ɔ',
    '±'     => 'Ɔ',
    'ß'     => 'œ',
    'ÿ'     => 'ʉ',
    'œ'     => 'ŋ',
    'Ø'     => 'Ŋ',
    '∆'     => "\x{300}", # combining grave
    '◊'     => "\x{301}", # combining acute
    'æ'     => "\x{301}", # combining acute
    'û'     => "\x{301}", # combining acute
    '¶'     => "\x{301}", # combining acute
    'Ã'     => "\x{302}", # combining circumflex
    '»'     => "\x{302}", # combining circumflex
    '‹'     => "\x{308}", # combining diaeresis
    'Ÿ'     => "\x{30C}", # combining caron
    '¿'     => "\x{30C}", # combining caron
    '¡'     => "\x{327}", # combining cedilla
    '°'     => "\x{327}", # combining cedilla
);

my $data = do { local $/; <$in> };

$data = join('', map { exists $MAP{$_} ? $MAP{$_} : chr(ord($_)+1) } split //, $data);

print $out NFC($data);