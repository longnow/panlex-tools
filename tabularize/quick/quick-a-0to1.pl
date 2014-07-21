#!/usr/bin/perl -w

# Processes a “quick” source containing distinct “dict” and “index” files. Uses the
# “index” files to discover the entries in the “dict” files.

use Encode 'decode';
# Import the library subroutine to decode octets.

my $name = $ARGV[0];
# Identify the stem of the file names.

open INDEX, '<:utf8', "$name.index";
# Open the index file for reading.

open DICTIN, '<:unix', "$name.dict";
# Open the dict file for reading.

open DICTOUT, '>:utf8', "$name.txt";
# Create an output file and open it for writing.

my $main = '';
# Initialize the line as being in the file header.

my (@sl64, @s64, @l64, $i, @head, $start, @start, $length, @length);

my $alph64 = (join '', (('A' .. 'Z'), ('a' .. 'z'), ('0' .. '9'), '+', '/'));
# Identify the 64 digits of the number system.

while (<INDEX>) {
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

		@isl64 = m#^(.+)\t(.+)\t(.+)$#;
		# Identify the headword, start, and length specified in the line.

		@s64 = (split //, $isl64[1]);
		# Identify the digits of the start.

		@l64 = (split //, $isl64[2]);
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

		push @head, $isl64[0];
		# Append the headword to the list of headwords.

		push @start, $start;
		# Append the start to the list of starts.

		push @length, $length;
		# Append the length to the list of lengths.

	}

}

my $dict = '';
# Initialize the dict file’s content as empty.

my ($tail, $prior);

while (<DICTIN>) {
# For each line in the dict file:

	$dict .= $_;
	# Append it to the content.

}

foreach $i (0 .. $#start) {
# For each start:

	$tail = (&decode ('utf8', (substr $dict, $start[$i], $length[$i])));
	# Identify and UTF8-encode the entry tail in the dict file.

	$tail =~ s/\r/\n/g;
	# Replace all returns in the entry tail with newlines.

	chomp $tail;
	# Remove the entry tail’s trailing newline.

	$tail =~ s/\n/<&>/g;
	# Replace all newlines in the entry tail with “<&>”.

	print DICTOUT "$head[$i]\t$tail\n";
	# Output the entry.

}

close INDEX;

close DICTIN;

close DICTOUT;
