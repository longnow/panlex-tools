#!/usr/bin/env perl -w

# tab-curl-1to2.pl
# Corrects a tabularized html-curl file.
# Requires adaptation to the structure of each file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 1;
# Identify the input file's version.

#######################################################

open $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my @seg;

my $eng = '';
# Initialize the prior eng-000 expression as unknown.

my $wc = '';
# Initialize the prior wc as unknown.

while (<$in>) {
# For each line of the input file:

	if ((index $_, '¶') == 0) {
	# If it is an entry:

		$_ = (substr $_, 1);
		# Delete its entry marker.

		@seg = (split /\t/, $_, -1);
		# Identify its segments.

		if ($seg[0] eq '.') {
		# If the eng-000 expression is to be inherited:

			$seg[0] = $eng;
			# Make it inherit.

		}

		else {
		# Otherwise, i.e. if the eng-000 expression is not to be inherited:

			$seg[0] =~ s/^([^,]+), ([^,]+)$/$2 $1/;
			# If it is inverted with a comma delimiter, normalize it.

			$eng = $seg[0];
			# Make the prior eng-000 expression current.

		}

		if ($seg[1] eq '.') {
		# If the wc is to be inherited:

			$seg[1] = $wc;
			# Make it inherit.

		}

		else {
		# Otherwise, i.e. if the wc is not to be inherited:

			$wc = $seg[1];
			# Make the prior wc current.

		}

		print $out (join "\t", @seg[0, 2, 1, 3]);
		# Output it, with the wc column shifted to apply to the rop-000 column.

	}

}

close $in;
# Close the input file.

close $out;
# Close the output file.
