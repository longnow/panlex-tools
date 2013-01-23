#!/usr/bin/perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

require 'dedup.pl';
# Import a routine to delete duplicates.

#######################################################

my $fnbase = 'ttv-eng-T';
# Identify the filename base.

my $ver = 3;
# Identify the input file’s version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.txt";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my @col;

while (<DICIN>) {
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

	print DICOUT ((join "\t", @col) . "\n");
	# Output it.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
