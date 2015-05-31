#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open ':raw:encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Util;

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

while (<$in>) {
# For each line of the input file:

    chomp;
    # remove its trailing newline, if present.

    # while (s/, *(?![^()]*\))/‣/) {}
    $_ = Delimiter($_, ',', '‣');
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

    print $out $_, "\n";
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
