#!/usr/bin/perl -w

open DICIN, '<inputfile.txt';

open DICOUT, '>outputfile.txt';

while (<DICIN>) {
# For each line in the input file:

	s/\x00//g;
	# Delete all nulls.

	print DICOUT;
	# Output the line.

}

close DICIN;

close DICOUT;
