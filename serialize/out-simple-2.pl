# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#	0: variety UID of column 0.
#	1: variety UID of column 1.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.

open DICIN, '<:utf8', "$ARGV[0]-$ARGV[1].txt";
# Open the input file for reading.

open DICOUT, '>:utf8', "$ARGV[0]-$ARGV[2].txt";
# Create or truncate the output file and open it for writing.

print DICOUT ".\n2\n$ARGV[3]\n$ARGV[4]\n";
# Output the file header.

my %all;

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	s/⫷exp⫸[^⫷]+//g;
	# Delete all unnormalized expressions.

	unless (exists $all{$_}) {
	# If it is not a duplicate:

		$all{$_} = '';
		# Add it to the table of entries.

		s/\t?⫷ex⫸/\n/g;
		# Convert all expression tags and the inter-column tab.

		print DICOUT "$_\n";
		# Output the converted line.

	}

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
