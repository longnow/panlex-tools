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

my $VERSION = 4;
# Identify the input file's version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

while (<$in>) {
# For each line of the input file:

    chomp;
    # Delete its trailing newline.

    my @col = split /\t/, $_, -1;
    # Identify its columns.

    $col[1] =~ s/'/'/g;
    # Convert all right single quotation marks in column 1 to apostrophes.

    $col[2] =~ s/^None$//;
    # If column 2 is “None”, delete it.

    $col[3] =~ s/ *[,;] *(?![^()]*\))/‣/g;
    # Convert all unparenthesized commas and semicolons in column 3
    # to synonym delimiters.

    $col[3] =~ s/(?:^|‣)\Kto be /⫷wc:verb⫸(be) /g;
    # Convert all leading instances of “to be” to preposed verb
    # specifications and parenthesized “be” in column 3.

    $col[3] =~ s/(?:^|‣)\Kto /⫷wc:verb⫸/g;
    # Convert all leading instances of “to” to preposed verb
    # specifications in column 3.

    print $out join("\t", @col), "\n";
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
