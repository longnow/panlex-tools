#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

open my $out, '>', $ARGV[1] or die $!;

open my $in, '<', $ARGV[0] or die $!;

while (<$in>) {
# For each line in the input file:

	s/\x00//g;
	# Delete all nulls.

	print $out;
	# Output the line.

}

close $in;

close $out;
