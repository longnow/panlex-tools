#!/usr/bin/env perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $fnbase = 'ibb-eng-Brunett';
# Identify the filename base.

my $ver = 1;
# Identify the input file's version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.txt";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<DICIN>) {
# For each line of the input file:

	next unless (($_ ne "\n") && ((index $_, '<entry') == 0));
	# If it is not an entry, disregard it.

	next if /<relation type="paradigmatic-variant-from"/;
	# If it is nonlemmatic, disregard it.

	s%<example>.+?</example>%%g;
	# Delete all examples in it.

	s%<relation type="[^"]+" ref="[^"]+"/>%%g;
	# Delete all relation specifications in it.

	s%<trait[^/]+/>%%g;
	# Delete all trait specifications in it.

	print DICOUT;
	# Output it.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
