#!/usr/bin/perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $fnbase = 'wic-eng-Rood';
# Identify the filename base.

my $ver = 3;
# Identify the input file’s version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.txt";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my @col;

my %lv = (
	'wic', 1,
	'eng', 3
);
# Identify a table of language varieties and their columns.

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (('') x 4);
	# Reinitialize the output as a list of 4 blank columns.

	if (s/«mi=([^«»]+)»//) {
	# If the line contains a meaning identifier, delete it and:

		$col[0] = $1;
		# Make it the content of output column 0.

	}

	while (s/«ex([^=]+)=([^«»]+)»//) {
	# As long as the line contains any expression list, delete it and:

		$col[$lv{$1}] .= (((length $col[$lv{$1}]) ? '‣' : '') . $2);
		# Add it to its variety’s output column.

	}

	if (s/«wcmd=([^«»]+)»//) {
	# If the line contains a wc-md specification, delete it and:

		$col[2] = $1;
		# Make it the content of output column 2.

	}

	(print "$_\n") if (length $_);
	# If any content remains in the line, report it.

	print DICOUT ((join "\t", @col) . "\n");
	# Output it.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
