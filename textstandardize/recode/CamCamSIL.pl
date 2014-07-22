#!/usr/bin/perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $fnbase = 'filenamebase';
# Identify the filename base. Originally developed for gnd-fra-fub-Haller.

my $ver = 1;
# Identify the input file’s version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.txt";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<DICIN>) {
# For each line of the input file:

	tr/ãäàèëéêïìîñùÜ/\x{0327}ɓ\x{0301}\x{0300}ɗə\x{0302}i\x{0300}\x{0302}ŋ\x{0301}ʼ/;
	# Correct its encoding per Cam Cam SIL DoulosL and Cam Cam SIL SophiaL fonts.

	s/\.\.\./ … /g;
	# Convert all triple periods in it to diereses.

	print DICOUT;
	# Output it.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
