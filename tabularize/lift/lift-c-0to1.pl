#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.xml" or die $!;
# Open the input file for reading.

my $all = join('', <$in>);
# Identify the entire content of the input file.

$all =~ s/[^>]\K\n */ /g;
# Replace all newlines not preceded by tags and subsequent leading spaces in it
# with single spaces.

$all =~ s/\n *//g;
# Delete all other newlines and subsequent leading spaces in it.

$all =~ s/(?=<entry )/\n/g;
# Insert newlines before all entry start tags in it.

$all =~ s%</entry>\K%\n%g;
# Insert newlines after all entry end tags in it.

print $out $all;
# Output it.

close $in;
# Close the input file.

close $out;
# Close the output file.
