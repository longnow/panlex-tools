#!/usr/bin/perl -w

use encoding 'utf8';

open DICIN, '<:utf8', 'eng-khk-Temuka.txt';

open DICOUT, '>:utf8', 'eng-khk-Temuka-0.txt';

while (<DICIN>) {
# For each line in the input file:

	tr/№§ИПК/ѐѝѡҿӹ/;
	# Change deviantly encoded Cyrillic characters to what they should be, i.e. 16 more than the
	# correct Unicode codepoint. The last 2 changes were found necessary for khk-000.

	tr/А-ӿ/Ѐ-ӯ/;
	# Decrease the codepoint of every Cyrillic character by 16 except the first 16 Cyrillic
	# characters. Combining both “tr” statements fails, contrary to Perl documentation.

	print DICOUT;
	# Output the line.

}

close DICIN;

close DICOUT;