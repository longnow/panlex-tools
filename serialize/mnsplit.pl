# Splits multi-meaning lines of a tagged approver file, eliminating any duplicate output lines.
# Arguments:
#	0: base of the filename.
#	1: version of the file.
#	2: meaning-delimitation tag.
#	3: number (0-based) of the column that may contain multiple meanings.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w mnsplit.pl 'ces-epo-Procházka' 2 '⫷mn⫸' 0
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

open DICOUT, '>:utf8', ("$ARGV[0]-" . ($ARGV[1] + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my (@col, @line, %line, $line, $mn);

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	if ((index $col[$ARGV[3]], $ARGV[2]) < 0) {
	# If the potentially multimeaning column is one-meaning:

		unless (exists $line{$_}) {
		# If the line isn't a duplicate:

			$line{$_} = '';
			# Add it to the table of output lines.

			print DICOUT "$_\n";
			# Output it.

		}

	}

	else {
	# Otherwise, i.e. if the column is multimeaning:

		foreach $mn (split /$ARGV[2]/, $col[$ARGV[3]]) {
		# For each of its meaning segments:

			@line = @col;
			# Identify its line's columns, with the multimeaning column unchanged.

			$line[$ARGV[3]] = $mn;
			# Replace the multimeaning column with the meaning segment.

			$line = (join "\t", @line);
			# Identify the meaning's line.

			unless (exists $line{$line}) {
			# If it isn't a duplicate:

				$line{$line} = '';
				# Add it to the table of output lines.

				print DICOUT "$line\n";
				# Output it.

			}

		}

	}

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
