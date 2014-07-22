#!/usr/bin/perl -w

# Converts HTML decimal character entities to characters.

use HTML::Entities;
# Import a library for HTML entity conversion.

open DICIN, '<utf8', "$ARGV[0].txt";

open DICOUT, '>utf8', "$ARGV[1].txt";

my $line = '';
# Initialize the current line as blank.

while (<DICIN>) {
# For each line in the input file:

	print DICOUT decode_entities ($_);
	# Output it with its HTML character entities changed to the characters that they represent.

}

close DICIN;

close DICOUT;
