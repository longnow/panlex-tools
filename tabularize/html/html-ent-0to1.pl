#!/usr/bin/env perl

# Converts HTML decimal character entities to characters.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use HTML::Entities;
# Import a library for HTML entity conversion.

open my $out, '>:encoding(utf8)', "$ARGV[1].txt" or die $!;

open my $in, '<:encoding(utf8)', "$ARGV[0].txt" or die $!;

while (<$in>) {
# For each line in the input file:

	print $out (decode_entities ($_));
	# Output it with its HTML character entities changed to the characters that they represent.

}

close $in;

close $out;
