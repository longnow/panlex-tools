#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

open my $out, '>', 'NYIPA/NYIPA-mapcheck-nml.txt';
# Open the output file.

open my $map, '<', 'NYIPA/NYIPA-map-nml.txt';
# Open the map file.

while (<$map>) {
# For each line in the map file:

	chomp;
	# Delete its trailing newline.

	my @col = split /\t/, $_, -1;
	# Identiify its columns.

	print $out $col[0], "\t", $col[1], "\t", (chr (hex $col[1])), "\n";
	# Output the combined line.

}

close $map;

close $out;
