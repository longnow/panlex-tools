#!/usr/bin/perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $fnbase = 'aaa-bbb-Author';
# Identify the filename base.

my $ver = 0;
# Identify the input file’s version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.txt";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<DICIN>) {
# For each line of the input file:

	# while (s/, *(?![^()]*\))/‣/) {}
	s/ *, *(?![^()]*\))/‣/g;
	# Convert all unparenthesized commas in it to synonym delimiters.

	s/(?:^|\t|‣)\K +| +(?=$|\t|‣)//g;
	# Delete all leading and trailing spaces in it.

	s/ {2,}/ /g;
	# Collapse all multiple spaces in it.

	if (/^[^,]+\t(?:[^ ,]+, )+[^ ,]+$/) {
	# If column 0 contains no commas and column 1 is a sequence of
	# comma-delimited single words:

		s/, /⁋/g;
		# Convert all commas in the line to meaning delimiters.

	}

	print DICOUT;
	# Output it.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
