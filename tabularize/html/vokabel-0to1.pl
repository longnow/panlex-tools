#!/usr/bin/env perl

# Vokabel-0to1.pl
# Tabularizes a Vokabeltrainer html file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.html" or die $!;
# Open the input file for reading.

while (<$in>) {
# For each line of the input file:

    if (index($_, '<tr><td class="l1">') == 0) {
    # If it is an entry:

        chomp;
        # Delete its trailing newline.

        my @seg = m#^<tr><td class="l1">(.+?)</td><td class="l2">(.+?)</td></tr>#;
        # Identify its segments.

        print $out "$seg[0]\t$seg[1]\n" if @seg;
        # Output them, if they exist.
    }

}

close $in;
# Close the input file.

close $out;
# Close the output file.
