# Splits definitional expressions into reduced expressions and definitions in a source file with
# already-tagged expressions and tags the added definitions.
# Arguments:
#	0: expression tag in file.
#	1: regular expression matching any post-tag character.
#	2: regular expression matching any post-tag character that is not a space.
#	3: regular expression matching a definitional part of an expression.
#	4: definition tag to be used on definitions.
#	5: maximum character count permitted in an expression, or blank if none.
#	6: maximum word count permitted in an expression, or blank if none.
#	7: regular expression matching any substring forcing an expression to be
#		reclassified as a definition, or blank if none.
#	8: regular expression matching a preposed annotation not to be counted,
#		or blank if none.
#	9+: columns containing expressions that may contain definitional parts.

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

my ($df, $ex, $exorig, $i, @seg);

my $tmc = ($ARGV[7] ? ($ARGV[7] + 1) : '');
# Identify the character count of the shortest expression exceeding the maximum
# character count, or blank if none.

my @exdfcol = (@ARGV[11 .. $#ARGV]);
# Identify a list of the columns that may contain expressions with embedded definitions.

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@seg = (split /\t/, $_, -1);
	# Identify its columns.

	foreach $i (@exdfcol) {
	# For each of them that may contain expressions with embedded definitions or
	# expressions classifiable as definitions:

		if (length $ARGV[5]) {
		# If there is a criterion for definitional substrings:

			while ($seg[$i] =~ /($ARGV[2]$ARGV[3]*$ARGV[5]$ARGV[3]*)/o) {
			# As long as any expression in the column satisfies the criterion:

				$df = $ex = $1;
				# Identify the expression and a definition identical to it.

				$df =~ s/^$ARGV[2](?:$ARGV[10])?/$ARGV[6]/o;
				# In the definition, change the expression tag and any preposed annotation
				# to a definition tag.

				$ex =~ s/$ARGV[5]//og;
				# In the expression, delete all definitional substrings.

				$ex =~ s/ {2,}/ /g;
				# In the expression, collapse any multiple spaces.

				$ex =~ s/^$ARGV[2](?:$ARGV[10])?\K | $//og;
				# In the expression, delete all initial and final spaces.

				($ex = '') if (
					($ex eq $ARGV[2])
					|| (($ARGV[7]) && ($ex =~ /^$ARGV[2](?:$ARGV[10])?+.{$tmc}/o))
					|| (($ARGV[8]) && ($ex =~ /^(?:[^ ]+ ){$ARGV[8]}/o))
					|| ((length $ARGV[9]) && ($ex =~ /^$ARGV[2](?:$ARGV[10])?$ARGV[3]*$ARGV[9]/))
				);
				# If the expression has become blank, exceeds a maximum count, or contains
				# a prohibited character, delete the expression. (The possessive quantifier
				# prohibits including a preposed annotation in the count.)

				$seg[$i] =~ s/$ARGV[2]$ARGV[3]*$ARGV[5]$ARGV[3]*/$df$ex/o;
				# Replace the expression with the definition and the reduced expression.

			}

		}

		($seg[$i] =~ s/$ARGV[2](?:$ARGV[10])?(${ARGV[3]}{$tmc,})/$ARGV[6]$1/og)
			if $tmc;
		# Convert every expression in the column that exceeds the maximum character
		# count, if there is one, to a definition, omitting any preposed annotation.

		($seg[$i] =~ s/$ARGV[2](?:$ARGV[10])?((?:$ARGV[4]+ ){$ARGV[8]})/$ARGV[6]$1/og)
			if $ARGV[8];
		# Convert every expression in the column that exceeds a maximum word count,
		# if there is one, to a definition, omitting any preposed annotation.

		($seg[$i] =~ s/$ARGV[2](?:$ARGV[10])?($ARGV[3]*(?:$ARGV[9]))/$ARGV[6]$1/og)
			if (length $ARGV[9]);
		# Convert every expression containing a prohibited character, if there is any,
		# to a definition, omitting any preposed annotation.

	}

	print DICOUT ((join "\t", @seg) . "\n");
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
