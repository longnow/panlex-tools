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

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

while (<$in>) {
# For each line of the input file:

    # while (s/, *(?![^()]*\))/‣/) {}
    s/ *, *(?![^()]*\))/‣/g;
    # Convert all unparenthesized commas in it to synonym delimiters.

    s/(?:^|\t|‣)\K +| +(?=$|\t|‣)//g;
    # Delete all leading and trailing spaces in it.

    s/ {2,}/ /g;
    # Collapse all multiple spaces in it.

    if (/^[^,]+\t(?:[^ ,]+, )+[^ ,]+$/) {
    # If column 0 contains no commas and column 1 is a sequence of
    # comma-delimited single words:

        s/, /⁋/g;
        # Convert all commas in the line to meaning delimiters.

    }

    print $out $_;
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
