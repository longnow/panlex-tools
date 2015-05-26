#!/usr/bin/env perl

# html-0to1.pl
# Tabularizes an html file.
# Requires adaptation to the structure of each file.
# NOT YET TESTED AND DEBUGGED.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use HTML::Entities 'decode_entities';
# Import subroutines to decode HTML character entities.

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

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.html" or die $!;
# Open the input file for reading.

my @all = <$in>;
# Identify a list of all lines of the input file.

chomp @all;
# Delete their trailing newlines.

my $all = decode_entities(join '', @all);
# Identify their concatenation, with HTML entities decoded.

$all =~ s/>\K\s+//g;
# Delete all whitespace characters immediately after right angle brackets in it.

$all =~ s/\n/ /g;
# Convert all other newlines in it to spaces.

my @tr = ($all =~ m%<tr.+?>(.+?)</tr>%g);
# Identify a list of its tr elements.

foreach my $tr (@tr) {
# For each of them:

    my @td = ($tr =~ m%<td.*?>([^<>]+?)<.*?/td>%g);
    # Identify a list of the first of its nonblank td elements’ innermost contents.

    print $out join("\t", @td), "\n" if length(join('', @td));
    # Output it unless all elements of the list are blank.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
