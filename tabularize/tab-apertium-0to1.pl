#!/usr/bin/perl -w

# tab-apertium-0to1.pl
# Tabularizes an Apertium .dix file, eliminating duplicate entries.
# Outputs a 4-column table with columns ex, wc, ex, wc.

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

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.dix";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my %st;

while (<DICIN>) {
# For each line of the input file:

	s#<b/># #g;
	# Replace all “b” tags in it with spaces.

	s#</?g>##g;
	# Delete all “g” tags in it.

	if (m#^ +<e><p><l>([^!-@].*?)<s n="([^"]+)"/>.*?</l><r>(.+?)<s n="([^"]+)"/>.*?</r></p></e>#) {
	# If it is an entry:

		unless (exists $st{"$1•$2•$3•$4"}) {
		# If it isn’t a duplicate:

			$st{"$1•$2•$3•$4"} = '';
			# Add it to the table of entries.

			print DICOUT "$1\t$2\t$3\t$4\n";
			# Output its columns.

		}

	}

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
