#!/usr/bin/env perl

# Deletes trailing nul characters and reformats .wb file as tab-delimited lines without changing
# encoding. Various wb files use various encodings.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

open my $in, '<', 'inputfile.wb' or die $!;

open my $out, '>', 'outputfile.txt' or die $!;

$ret = '';
# Initialize the result as blank.

while (<$in>) {
# For each line in the input file (normally only 1 in a wb file):

	$ret .= $_;
	# Append it to the result.

}

$ret =~ s/(.{31})(.{53})/$1\t$2\n/g;
# Partition the result into 84-character segments, then reformat each segment as a line with a tab
# after the first 31 characters.

$ret =~ s/[\x00][^\t\n]*//g;
# Delete every nul and every character after any null before the next tab or newline.

print $out $ret;
# Output the result.

close $in;

close $out;
