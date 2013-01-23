# Converts a normally tagged approver file to a simple-text bilingual approver file,
# eliminating duplicates.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: version of the output file.
#	3: variety UID of column 0.
#	4: variety UID of column 1.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w simple-2.pl 'epo-hun-Wüster' '5' 'final' 'epo-000' 'hun-000'
# The -C63 switch ensures that argument 2 is treated as UTF8-encoded. If it is used within the
# script, it is “too late”.

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
