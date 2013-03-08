#!/usr/bin/env perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $BASENAME = 'ibb-eng-Brunett';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open $in, '<:encoding(utf8)', "$BASENAME-$VERSION.xml";
# Open the input file for reading.

open $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my $all = (join '', <$in>);
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
