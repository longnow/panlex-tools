# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file and deletes word class specifications
# prepended to definitions.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: column containing word class specifications.
#	3: start of word-class specification.
#	4: end of word-class specification.
#	5: word-classification tag.
#	6: expression tag.
#	7: regular expression matching any post-tag character.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w wcshift.pl 'art-eng-Ingsve' 7 2 '«wc:' '»' '⫷wc⫸' '⫷ex⫸' '[^⫷]'
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
