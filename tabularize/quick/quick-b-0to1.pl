#!/usr/bin/env perl

# Processes a source containing distinct “dict” and “index” files with the first
# column of the index file useless. Uses the index files to discover the entries in the dict files.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use open IO => ':raw:encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

my $name = $ARGV[0];
# Identify the stem of the file names.

open my $out, '>:unix', "$name.txt" or die $!;
# Create an output file and open it for writing.

open my $index, '<', "$name.index" or die $!;
# Open the index file for reading.

open my $in, '<:unix', "$name.dict" or die $!;
# Open the dict file for reading.

my $main = '';
# Initialize the line as being in the file header.

my (@sl64, @s64, @l64, $i, $start, @start, $length, @length);

my $alph64 = (join '', (('A' .. 'Z'), ('a' .. 'z'), ('0' .. '9'), '+', '/'));
# Identify the 64 digits of the number system.

while (<$index>) {
# For each line in the index file:

	unless ($main) {
	# If the line is in the file header:

		($main = 1) if ((substr $_, 0, 2) ne '00');
		# Identify the line as in the file body if it doesn’t begin with “00”.

	}

	if ($main) {
	# If the line is in the file body:

		chomp;
		# Remove its trailing newline.

		@sl64 = m#^.+\t(.+)\t(.+)$#;
		# Identify the start and length specified in the line.

		@s64 = (split //, $sl64[0]);
		# Identify the digits of the start.

		@l64 = (split //, $sl64[1]);
		# Identify the digits of the length.

		$start = 0;
		# Initialize the start as 0.

		foreach $i (0 .. $#s64) {
		# For each digit in the start:

			$start += ((64 ** $i) * (index($alph64, $s64[$#s64 - $i])));
			# Increase the start by the amount the digit represents.

		}

		$length = 0;
		# Initialize the length as 0.

		foreach $i (0 .. $#l64) {
		# For each digit in the length:

			$length += ((64 ** $i) * (index($alph64, $l64[$#l64 - $i])));
			# Increase the length by the amount the digit represents.

		}

		push @start, $start;
		# Append the start to the list of starts.

		push @length, $length;
		# Append the length to the list of lengths.

	}

}

my $dict = '';
# Initialize the dict file’s content as empty.

my ($entry, $prior);

while (<$in>) {
# For each line in the dict file:

	$dict .= $_;
	# Append it to the content.

}

foreach $i (0 .. $#start) {
# For each start:

	$entry = (substr $dict, $start[$i], $length[$i]);
	# Identify the entry in the dict file.

	$entry =~ s/\r/\n/g;
	# Replace all returns in the entry with newlines.

	chomp $entry;
	# Remove the entry’s trailing newline.

	$entry =~ s/\n/<&>/g;
	# Replace all newlines in the entry with “<&>”.

	print $out "$entry\n";
	# Output the entry.

}

close $in;

close $index;

close $out;

