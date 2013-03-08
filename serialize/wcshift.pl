# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file.
# Arguments:
#	0: column containing prepended word class specifications.
#	1: start of word-class specification.
#	2: end of word-class specification.
#	3: word-classification tag.
#	4: expression tag.
#	5: regular expression matching any post-tag character.

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

my (@col);

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	$col[$ARGV[2]] =~ s/$ARGV[6]$ARGV[3](.+?)$ARGV[4]($ARGV[7]+)/$ARGV[6]$2$ARGV[5]$1/g;
	# Replace all word class specifications prepended to expressions with post-ex wc tags.

	$col[$ARGV[2]] =~ s/$ARGV[3](.+?)$ARGV[4]//g;
	# Delete all other word class specifications, including those prepended to definitions.

	print DICOUT ((join "\t", @col), "\n");
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
