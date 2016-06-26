#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

#######################################################

my $BASENAME = 'filenamebase';
# Identify the filename base. Originally developed for gnd-fra-fub-Haller.

my $VERSION = 1;
# Identify the input file’s version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

while (<$in>) {
# For each line of the input file:

	tr/ãäàèëéêïìîñùÜ/\x{0327}ɓ\x{0301}\x{0300}ɗə\x{0302}i\x{0300}\x{0302}ŋ\x{0301}ʼ/;
	# Correct its encoding per Cam Cam SIL DoulosL and Cam Cam SIL SophiaL fonts.

	s/\.{3}/ … /g;
	# Convert all triple periods in it to diereses.

	print $out;
	# Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
