# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: definition tag.
#	3+: columns containing definitions.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w dftag.pl 'aaa-bbb-Author' 2 '⫷df⫸' 1 2
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

my (@col, $i);

my @dfcol = (@ARGV[3 .. $#ARGV]);
# Identify a list of the definition columns.

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	foreach $i (@dfcol) {
	# For each definition column:

		($col[$i] = "$ARGV[2]$col[$i]") if (length $col[$i]);
		# Prefix a definition tag to the column, if not blank.

	}

	print DICOUT (join "\t", @col), "\n";
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
