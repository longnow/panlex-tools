#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use encoding 'utf8';
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.

open my $out, '>:utf8', 'NYIPA/NYIPA-mapcheck-nml.txt';
# Open the output file.

open my $map, '<', 'NYIPA/NYIPA-map-nml.txt';
# Open the map file.

my @col;

while (<$map>) {
# For each line in the map file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/);
	# Identiify its columns.

	print $out $col[0], "\t", $col[1], "\t", (chr (hex $col[1])), "\n";
	# Output the combined line.

}

close $map;

close $out;
