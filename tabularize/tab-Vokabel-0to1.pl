#!/usr/bin/env perl -w

# tab-html-0to1.pl
# Tabularizes an html file.
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

my $ver = 0;
# Identify the input file’s version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.html";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my @seg;

while (<DICIN>) {
# For each line of the input file:

	if ((index $_, '<tr><td class="l1">') == 0) {
	# If it is an entry:

		chomp;
		# Delete its trailing newline.

		@seg = m#^<tr><td class="l1">(.+?)</td><td class="l2">(.+?)</td></tr>#;
		# Identify its segments.

		(print DICOUT "$seg[0]\t$seg[1]\n") if @seg;
		# Output them, if they exist.

	}

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
