# Tags metadata in a tab-delimited source file.
# Arguments:
#	0: column containing metadata.
#	1: metadatum tag.

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

my @col;

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	($col[$ARGV[2]] = "$ARGV[3]$col[$ARGV[2]]") if (length $col[$ARGV[2]]);
	# Prefix a meaning-identifier tag to the meaning-identifier column's content,
	# if not blank.

	print DICOUT ((join "\t", @col), "\n");
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
