#!/usr/bin/env perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $BASENAME = 'byv-eng-M';
# Identify the filename base.

my $VERSION = 4;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my @col;

while (<$in>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = split /\t/, $_, -1;
	# Identify its columns.

	$col[1] =~ s/'/'/g;
	# Convert all right single quotation marks in column 1 to apostrophes.

	$col[2] =~ s/^None$//;
	# If column 2 is “None”, delete it.

	$col[3] =~ s/ *[,;] *(?![^()]*\))/‣/g;
	# Convert all unparenthesized commas and semicolons in column 3
	# to synonym delimiters.

	$col[3] =~ s/(?:^|‣)\Kto be /⫷wc:verb⫸(be) /g;
	# Convert all leading instances of “to be” to preposed verb
	# specifications and parenthesized “be” in column 3.

	$col[3] =~ s/(?:^|‣)\Kto /⫷wc:verb⫸/g;
	# Convert all leading instances of “to” to preposed verb
	# specifications in column 3.

	print $out join("\t", @col), "\n";
	# Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
