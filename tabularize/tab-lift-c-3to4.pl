#!/usr/bin/env perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

require 'dedup.pl';
# Import a routine to delete duplicates.

#######################################################

my $BASENAME = 'ttv-eng-T';
# Identify the filename base.

my $VERSION = 3;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my @col;

while (<$in>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	next unless (length $col[2]);
	# If there are no translations or definitions, disregard the line.

	$col[1] = (&Dedup ($col[1], '‣'));
	# Delete duplicates in column 1.

	$col[2] =~ s%</sense><sense>%\n$col[0]\t$col[1]\t%g;
	# Split it on all meaning changes.

	$col[2] =~ s%</?sense>%%g;
	# Delete the remaining sense tags in column 2.

	print $out ((join "\t", @col) . "\n");
	# Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
