#!/usr/bin/perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use encoding 'utf8';
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.

open MAP, 'NYIPA/NYIPA-map-nml.txt';
# Open the map file.

open OUT, '>:utf8', 'NYIPA/NYIPA-mapcheck-nml.txt';
# Open the output file.

my @col;

while (<MAP>) {
# For each line in the map file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/);
	# Identiify its columns.

	print OUT $col[0], "\t", $col[1], "\t", (chr (hex $col[1])), "\n";
	# Output the combined line.

}

close MAP;

close OUT;
