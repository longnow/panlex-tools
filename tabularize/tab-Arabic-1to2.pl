#!/usr/bin/perl -w

# tab-curl-1to2.pl
# Corrects a tabularized html-curl file.
# Requires adaptation to the structure of each file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $fnbase = 'aaa-bbb-Author';
# Identify the filename base.

my $ver = 1;
# Identify the input file’s version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.txt";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<DICIN>) {
# For each line of the input file:

	if ((index $_, '¶') == 0) {
	# If it is an entry:

		$_ = (substr $_, 1);
		# Delete its entry marker.

		s/\t1\. /\t/;
		# Delete any initial meaning index.

		s/ (?:\d\.|---) /⁋/g;
		# Replace all subsequent meaning indices and triple hyphen-minuses with
		# meaning delimiters.

		while (s/[,\x{060c}](?![^()]+\))/‣/) {}
		# Replace all unparenthesized commas and Arabic commas with synonym delimiters.

		s/ {2,}/ /g;
		# Collapse all multiple spaces.

		s/(?:^|\t|‣|⁋)\K +//g;
		# Delete all leading spaces.

		s/ +(?=\t|‣|⁋|$)//g;
		# Delete all trailing spaces.

		print DICOUT;
		# Output it.

	}

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.