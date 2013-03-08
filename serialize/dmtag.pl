# Tags domain expressions in a tab-delimited source file.
# Arguments:
#	0: domain-expression tag.
#	1: inter-expression delimiter, or blank if none.
#	2+: columns containing domain expressions.

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

my (@col, $i);

while (<DICIN>) {
# For each line of the input file:

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	foreach $i (4 .. $#ARGV) {
	# For each domain-expression column:

		if (length $ARGV[3]) {
		# If there is an inter-expression delimiter:

			$col[$ARGV[$i]] =~ s/(^|$ARGV[3])(?!$|$ARGV[3])/$ARGV[2]/g;
			# Prefix each element of the column's value with a domain-expression tag.

		}

		else {
		# Otherwise, i.e. if there is no inter-expression delimiter:

			$col[$ARGV[$i]] = "$ARGV[2]$col[$ARGV[$i]]";
			# Prefix the column's value with a domain-expression tag.

		}

	}

	print DICOUT (join "\t", @col);
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
