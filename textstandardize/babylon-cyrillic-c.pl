#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

open my $out, '>', 'eng-ukr-BlekhmanMEUL-0.txt';

open my $in, '<', 'eng-ukr-BlekhmanMEUL.txt';

while (<$in>) {
# For each line in the input file:

	tr/№§ИГКП/ѐѝѡѦѤѧ/;
	# Change deviantly encoded Cyrillic characters to what they should be, i.e. 16 more than the
	# correct Unicode codepoint. The last 3 changes were found necessary for ukr-000.

	tr/А-ӿ/Ѐ-ӯ/;
	# Decrease the codepoint of every Cyrillic character by 16 except the first 16 Cyrillic
	# characters. Combining both “tr” statements fails, contrary to Perl documentation.

	print $out;
	# Output the line.

}

close $in;

close $out;
