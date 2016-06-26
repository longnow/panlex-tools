#!/usr/bin/env perl

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

use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Util;

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 3;
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

    next unless (length $col[2]);
    # If there are no translations or definitions, disregard the line.

    $col[1] = (&Dedup ($col[1], '‣'));
    # Delete duplicates in column 1.

    $col[2] =~ s%</sense><sense>%\n$col[0]\t$col[1]\t%g;
    # Split it on all meaning changes.

    $col[2] =~ s%</?sense>%%g;
    # Delete the remaining sense tags in column 2.

    print $out join("\t", @col), "\n";
    # Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
