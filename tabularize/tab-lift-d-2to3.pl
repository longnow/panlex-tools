#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 2;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<$in>) {
# For each line of the input file:

    s%<note.+?</note>%%g;
    # Delete all note elements in it.

    s%<(form|gloss) lang="([^"]+)"><text>(?:[A-Z][^:]+: +)?([^<>]+)</text></\1>%⫷ex$2=$3⫸%g;
    # Shorten all expression specifications in it.

    s%^<entry id="([^"]+)">%⫷mi=$1⫸%;
    # Shorten its mi.

    s%<grammatical-info value="([^"]+)"/>%⫷wcmd=$1⫸%g;
    # Shorten all wc-md specifications in it.

    s%<[^<>]+>%%g;
    # Delete all remaining tags in it.

    print $out $_;
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
