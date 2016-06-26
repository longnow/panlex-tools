#!/usr/bin/env perl

# Jonathan Pool
# Revision: 18 September 02015

# Creates lists of distinct characters, by font, from a file of “»”-delimited pseudolists,
# where each element is a colon-delimited pseudolist of 2 elements, of which element 0 is a
# font name and element 1 is the base64 encoding of the UTF-8 encoding of the text of an
# expression.

# Special case: The input file may be the final source file (submitted to, or retrieved from,
# the database) containing only meaning properties whose values are as described above.

# Purpose: to limit the effort of compiling a map from a non-Unicode font to Unicode by
# disclosing which non-Unicode characters need to be mapped so that a particular source can
# be converted.

# Use case: An editor may have submitted the source as a set of meanings with 1 property per
# meaning, with art-270:2544 (origin) as the attribute expression and the above-described
# pseudolist as the value.

# Example of a line in an input file:
# Arial:R3JhdGVyIEdhbGFuZ2Fs»GJBW-TTAvantika:w6/DtcObw6nDncOFw5vigLrDt8K2w5s=

# Command-line arguments:
# 0: input file.
# 1: output file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

use MIME::Base64;
# Import subroutines to encode and decode base64.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

open my $in, '<', $ARGV[0];

open my $out, '>', $ARGV[1];

my %all;

while (<$in>) {
# For each line of the input file:

	next unless /.:/;
	# Disregard it if it contains no non-initial colon.

	my @el = (split /»/);
	# Identify its elements, each being a font-prefixed expression text.

	foreach my $el (@el) {
	# For each of them:

		my @subel = (split /:/, $el, 2);
		# Identify its font name and encoded expression text.

		$subel[0] =~ s/\s//g;
		# Delete all whitespace characters in the font name.

		$subel[1] = (decode_base64 ($subel[1]));
		# Decode the expression text from base64 to UTF-8.

		utf8::decode ($subel[1]);
		# Decode it from UTF-8 to characters.

		$all{$subel[0]} .= $subel[1];
		# Initialize or append to the concatenation of texts in the font.

	}

}

foreach my $font (sort (keys %all)) {
# For each encountered font:

	my %chr;

	my $ccat = $all{$font};
	# Identify the concatenation of the texts of the expressions in it.

	foreach my $chr (0 .. ((length $ccat) - 1)) {
	# For each character token:

		$chr{substr $ccat, $chr, 1} = '';
		# Ensure that its character is in the font’s character table.

	}

	print $out "#### Font $font ####\n";
	# Output the font name.

	foreach my $chr (sort (keys %chr)) {
	# For each character in the font’s character table:

		my $cpt = (ord $chr);
		# Identify its numeric value, i.e. codepoint.

		my $hex = (sprintf '%05x', $cpt);
		# Identify its hexadecimal representation.

		print $out "$hex\t$chr\t0\n";
		# Output it, the character, and an initial “0” of a mapping, tab-delimited.

	}

}

close $in;
# Close the input file.

close $out;
# Close the output file.
