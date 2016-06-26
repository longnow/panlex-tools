#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

my %lv = (
	'Proto-Aaaa', 1,
	'Bbbb', 2,
	'Cccc', 3,
	'Dddd', 4
);
# Identify a table of language varieties.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

my ($app, @col, $col, $eng, %entry, $entry, $extt, $lvtt, @out);

while (<$in>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	if (/^Word: (.+)$/) {
	# If it is an eng-000 expression:

		$eng = $1;
		# Identify the expression.

		$eng =~ s/ ([a-z]+\.)$/ ($1)/;
		# Parenthesize any trailing abbreviation in it.

	}

	elsif (/^((?:Proto-|=).+?): ([^\d].+)$/) {
	# Otherwise, if it is an expression in another language variety:

		$lvtt = $1;
		# Identify the language variety’s name.

		$extt = $2;
		# Identify the expression.

		$extt =~ s/ ?\([^()]+\)//g;
		# Delete all parenthesized parts of it.

		$extt =~ s/ ?\[[^()]+\]//g;
		# Delete all bracketed parts of it.

		$app = ($lv{$lvtt} . ':' . $extt);
		# Identify the language variety’s column and the expression.

		if (exists $entry{$eng}) {
		# If an entry for the last previous eng-000 expression exists:

			$entry{$eng} .= "#$app";
			# Append the language variety’s column and the expression to the entry,
			# with a prepended delimiter.

		}

		else {
		# Otherwise, i.e. if no entry for the last previous eng-000 expression exists:

			$entry{$eng} = $app;
			# Initialize it with the language variety’s column and the expression.

		}

	}

}

foreach $entry (sort (keys %entry)) {
# For each entry:

	@out = ($entry, (('') x 5));
	# Initialize its output list.

	@col = (split /#/, $entry{$entry});
	# Identify its columns.

	foreach $col (@col) {
	# For each of them:

		$col =~ /^(\d):(.+)$/;
		# Identify its elements.

		$out[$1] = $2;
		# Populate its language variety’s element of the output list.

	}

	print $out ((join "\t", @out) . "\n");
	# Output the entry.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
