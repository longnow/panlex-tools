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

my $VERSION = 3;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

my %lv = (
    'wic', 1,
    'eng', 3
);
# Identify a table of language varieties and their columns.

while (<$in>) {
# For each line of the input file:

    chomp;
    # Delete its trailing newline.

    my @col = (('') x 4);
    # Reinitialize the output as a list of 4 blank columns.

    if (s/⫷mi=([^⫷⫸]+)⫸//) {
    # If the line contains a meaning identifier, delete it and:

        $col[0] = $1;
        # Make it the content of output column 0.

    }

    while (s/⫷ex([^=]+)=([^⫷⫸]+)⫸//) {
    # As long as the line contains any expression list, delete it and:

        $col[$lv{$1}] .= (((length $col[$lv{$1}]) ? '‣' : '') . $2);
        # Add it to its variety's output column.

    }

    if (s/⫷wcmd=([^⫷⫸]+)⫸//) {
    # If the line contains a wc-md specification, delete it and:

        $col[2] = $1;
        # Make it the content of output column 2.

    }

    print "$_\n" if length $_;
    # If any content remains in the line, report it.

    print $out join("\t", @col), "\n";
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
