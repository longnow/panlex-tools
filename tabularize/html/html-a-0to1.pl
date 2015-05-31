#!/usr/bin/env perl

# html-0to1.pl
# Tabularizes an html file.
# Requires adaptation to the structure of each file.

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

my $state = 1;
# Initialize the state as in-entry.

while (<$in>) {
# For each line of the input file:

    chomp;
    # Delete its trailing newline.

    if (/^<tr/) {
    # If it is the start of a row:

        $state = 1;
        # Identify the state as in-entry.

    }

    elsif (m#^</tr#) {
    # Otherwise, if it is the end of a row:

        print $out "\n";
        # Output a newline.

        $state = 0;
        # Identify the state as not in-entry.

    }

    elsif (($state == 1) && (m#^<div class=paragraph .+<b>([^<>]+)</b></span></div>$#)) {
    # Otherwise, if the state is in-entry and the line is an entry line:

        print $out "\t$1";
        # Output its expression, preceded by a tab.

    }

}

close $in;
# Close the input file.

close $out;
# Close the output file.
