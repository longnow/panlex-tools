#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IO => ':raw:encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 2;
# Identify the input file's version.

my $lcs = 'sbe';
# Identify the source variety's lc per the input file.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

while (<$in>) {
# For each line of the input file:

    while (s%</text></form></lexical-unit><variant><form lang="$lcs"><text>([^<>]+)</text></form></variant>%‣$1</text></form></lexical-unit>%) {}
    # Convert all source-expression variants in it to synonyms.

    s%^<entry id="([^"]+)"><lexical-unit><form lang="$lcs"><text>([^<>]+)</text></form></lexical-unit>%$1\t$2\t%;
    # Convert its mi and source ex tt to columns.

    s%</entry>$%%;
    # Delete the closing entry tag in it.

    s%<grammatical-info value="([^"]+)"/>%⫷wcmd=$1⫸%g;
    # Shorten all wc-md specifications in it.

    s%<note><form lang="eng"><text>Tones: +([^<>]+)</text></form></note>%⫷tone=$1⫸%g;
    # Shorten all tone notes in it.

    s%<note type="dialect"><form lang="eng"><text>([^<>]+)</text></form></note>%⫷lvs=$1⫸%g;
    # Shorten all dialect notes in it.

    s%<note.+?</note>%%g;
    # Delete all other notes in it.

    s%<form lang="([^"]+)"><text>([^<>]+)</text></form>%⫷ex$1=$2⫸%g;
    # Shorten all translations in it.

    s%</?definition>%%g;
    # Delete all translation-enclosing tags in it.

    print $out $_;
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
