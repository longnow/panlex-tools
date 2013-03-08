# Converts a normally tagged approver file to a simple-text varilingual approver file,
# eliminating duplicates.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: version of the output file.
#	3+: specifications (column index and variety UID, colon-delimited) of columns
#		containing expressions.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w out-simple-0.pl 'aaa-bbb-Author' 5 'final' '0:epo-000' '1:hun-000'
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

print DICOUT ".\n0\n";
# Output the file header.

my (%all, @col, %col, $en, $i);

foreach $i (3 .. $#ARGV) {
# For each expression column:

	@col = (split /:/, $ARGV[$i]);
	# Identify its specification parts.

	$col{$col[0]} = $col[1];
	# Add its index and variety UID to the table of expression columns.

}

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/);
	# Identify its columns.

	foreach $i (0 .. $#col) {
	# For each of them:

		if (exists $col{$i}) {
			# If it is an expression column:

			$col[$i] =~ s/⫷ex⫸/⫷ex:$col{$i}⫸/g;
			# Insert the column's variety UID into each expression tag in it.

		}

	}

	$en = (join '', @col);
	# Identify a concatenation of its modified columns.

	$en =~ s/⫷exp⫸.+?(?=⫷ex:)//g;
	# Delete all deprecated (i.e. pre-normalized) expressions in it.

	unless (exists $all{$en}) {
	# If it is not a duplicate:

		$all{$en} = '';
		# Add it to the table of entries.

		$en =~ s/⫷ex:([a-z]{3}-\d{3})⫸/\n$1\n/g;
		# Convert all expression tags in it.

		print DICOUT "$en\n";
		# Output the converted line.

	}

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
