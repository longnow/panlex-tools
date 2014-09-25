#!/usr/bin/env perl

# Deletes trailing nul characters and reformats .wb files as tab-delimited lines without changing
# encoding. Various wb files use various encodings. Some use one encoding for the source expression
# and another encoding for the target expression.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

chdir $ARGV[0];
# Change the working directory to the directory named in the first argument to this script’s
# invocation.

opendir my $dir, '.';
# Open it.

my ($ret, $out);

foreach $file (readdir $dir) {
# For each file in it:

	if ((substr $file, -3) eq '.wb') {
	# If it is a wb file, i.e. its name ends with “.wb”:

		open my $in, '<', $file or die $!;
		# Open it for reading.

		open my $out, '>', (substr $file, 0, -3) . '.txt') or die $!;
		# Open a new file with the same name except “.txt” as the extension for writing, replacing
		# any existing file with that name.

		$ret = '';
		# Initialize the result as blank.

		while (<$in>) {
		# For each line in the input file (normally only 1 in a .wb file):

			$ret .= $_;
			# Append it to the result.

		}

		$ret =~ s/(.{31})(.{53})/$1\t$2\n/g;
		# Partition the result into 84-character segments, then reformat each segment as a line
		# with a tab after the first 31 characters.

		$ret =~ s/[\x00][^\t\n]*//g;
		# Delete every nul and every character after any null before the next tab or newline.

		print $out $ret;
		# Output the result.

		close $in;
		# Close the input file.

		close $out;
		# Close the output file.

	}

}

closedir $dir;
# Close the working directory.
