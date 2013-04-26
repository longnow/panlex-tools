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

my $VERSION = 1;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<$in>) {
# For each line of the input file:

    next unless ($_ ne "\n" && index($_, '<entry') == 0);
    # If it is not an entry, disregard it.

    next if /<relation type="paradigmatic-variant-from"/;
    # If it is nonlemmatic, disregard it.

    s%<example>.+?</example>%%g;
    # Delete all examples in it.

    s%<relation type="[^"]+" ref="[^"]+"/>%%g;
    # Delete all relation specifications in it.

    s%<trait[^/]+/>%%g;
    # Delete all trait specifications in it.

    print $out $_;
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
