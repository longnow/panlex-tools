#!/usr/bin/perl -w

# Deletes trailing nul characters and reformats .wb files as tab-delimited lines without changing
# encoding. Various wb files use various encodings. Some use one encoding for the source expression
# and another encoding for the target expression.

chdir $ARGV[0];
# Change the working directory to the directory named in the first argument to this script’s
# invocation.

opendir DIR, '.';
# Open it.

my ($ret, $out);

foreach $file (readdir DIR) {
# For each file in it:

	if ((substr $file, -3) eq '.wb') {
	# If it is a wb file, i.e. its name ends with “.wb”:

		my $openresult = (open DICIN, $file);
		# Open it for reading.

		open DICOUT, ('>' . (substr $file, 0, -3) . '.txt');
		# Open a new file with the same name except “.txt” as the extension for writing, replacing
		# any existing file with that name.

		$ret = '';
		# Initialize the result as blank.

		while (<DICIN>) {
		# For each line in the input file (normally only 1 in a .wb file):

			$ret .= $_;
			# Append it to the result.

		}

		$ret =~ s/(.{31})(.{53})/$1\t$2\n/g;
		# Partition the result into 84-character segments, then reformat each segment as a line
		# with a tab after the first 31 characters.

		$ret =~ s/[\x00][^\t\n]*//g;
		# Delete every nul and every character after any null before the next tab or newline.

		print DICOUT $ret;
		# Output the result.

		close DICIN;
		# Close the input file.

		close DICOUT;
		# Close the output file.

	}

}

closedir DIR;
# Close the working directory.
