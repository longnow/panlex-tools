#!/usr/bin/perl -w

# Deletes trailing nul characters and reformats long-wb file as tab-delimited lines without
# changing encoding. Various .wb files use various encodings. Some use one encoding for the source
# expression and another encoding for the target expression.

open DICIN, 'Español_Arabela.wb';

open DICOUT, '>Español_Arabela.txt';

$ret = '';
# Initialize the result as blank.

while (<DICIN>) {
# For each line in the input file (normally only 1 in a wb file):

	$ret .= $_;
	# Append it to the result.

}

$ret =~ s/(.{201})(.{253})/$1\t$2\n/g;
# Partition the result into 454-character segments, then reformat each segment as a line with a tab
# after the first 201 characters.

$ret =~ s/[\x00][^\t\n]*//g;
# Delete every nul and every character after any null before the next tab or newline.

print DICOUT $ret;
# Output the result.

close DICIN;

close DICOUT;
