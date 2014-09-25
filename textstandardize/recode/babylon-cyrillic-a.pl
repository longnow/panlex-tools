#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

open my $out, '>:encoding(utf8)', 'ita-rus-Klimov-0.txt';

open my $in, '<:encoding(utf8)', 'ita-rus-Klimov.txt';

while (<$in>) {
# For each line in the input file:

	tr/№§И/ѐѝѡ/;
	# Change deviantly encoded Cyrillic characters to what they should be, i.e. 16 more than the
	# correct Unicode codepoint.

	tr/А-ӿ/Ѐ-ӯ/;
	# Decrease the codepoint of every Cyrillic character by 16 except the first 16 Cyrillic
	# characters. Combining both “tr” statements fails, contrary to Perl documentation.

	print $out;
	# Output the line.

}

close $in;

close $out;
