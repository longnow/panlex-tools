# Tags all expressions and all intra-column meaning changes in a tab-delimited approver file,
# disregarding any definitional parts.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: expression delimiter (regular expression), or blank if none.
#	3: meaning delimiter (regular expression), or blank if none.
#	4: expression tag.
#	5: meaning tag.
#	6+: columns containing expressions.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w extag.pl 'ces-epo-Procházka' 2 '‣' '⁋' '⫷ex⫸' '⫷mn⫸' 1 2
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

my @excol = (@ARGV[6 .. $#ARGV]);
# Identify a list of the expression columns.

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	foreach $i (@excol) {
	# For each expression column:

		($col[$i] =~ s/$ARGV[2]/$ARGV[4]/g) if (length $ARGV[2]);
		# Convert each expression delimiter in it to an expression tag, if expression
		# delimiters exist.

		($col[$i] =~ s/$ARGV[3]/$ARGV[5]$ARGV[4]/g) if (length $ARGV[3]);
		# Convert each meaning delimiter in it to a meaning tag and an expression tag,
		# if meaning delimiters exist.

		($col[$i] = "$ARGV[4]$col[$i]") if ((length $col[$i]) && ($col[$i] !~ /^(?:$ARGV[4]|$ARGV[5])/));
		# Prefix an expression tag to the column, if not blank and not already
		# containing a leading expression or meaning tag.

		$col[$i] =~ s/$ARGV[4](?=$ARGV[4]|$ARGV[5]|$)//g;
		# Delete all expression tags with blank contents.

		$col[$i] =~ s/$ARGV[5](?=$ARGV[5]|$)//g;
		# Delete all meaning tags with blank contents.

	}

	print DICOUT (join "\t", @col), "\n";
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
