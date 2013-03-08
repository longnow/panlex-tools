#!/usr/bin/env perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use Encode 'decode_utf8';
# Import a routine to decode from UTF-8 to character values.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open DICIN, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open SEG2OLD, '>:encoding(utf8)', ("$BASENAME-seg2-$VERSION.txt");
# Create or truncate the recoding input file and open it for writing.

open DICOUT, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<DICIN>) {
# For each line of the input file:

	print SEG2OLD (split /\t/)[2];
	# Output its segment 2 to the recoding input file.

}

close DICIN;
# Close the input file.

close SEG2OLD;
# Close the recoding input file.

my $newver = ($VERSION + 1);
# Identify the new version.

`txtconv -t secondary/kantipur.tec -i "$BASENAME-seg2-$VERSION.txt" -o "$BASENAME-seg2-$newver.txt"`;
# Recode the recoding input file.

open DICIN, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file again for reading.

open SEG2NEW, '<:encoding(utf8)', "$BASENAME-seg2-$newver.txt";
# Open the recoding output file for reading.

my (@seg, $seg2);

while (<DICIN>) {
# For each line of the input file:

	@seg = (split /\t/);
	# Identify its segments.

	$seg2 = <SEG2NEW>;
	# Identify the corresponding recoded segment 2.

	($seg2 = "\n") if ($seg2 =~ /\x{fffd}/);
	# If it contains an invalid character, make it blank.

	print DICOUT "$seg[0]\t$seg[1]\t$seg2";
	# Output segments 0 and 1 of the line and the recoded segment 2.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
