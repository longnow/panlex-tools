#!/usr/bin/env perl

# Combines two files as the left and right columns of a new file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use open ':raw:encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

open my $combo, '>', $ARGV[2];

open my $left, '<', $ARGV[0];

open my $right, '<', $ARGV[1];

my $line = '';
# Initialize the line as blank.

my $leftside = '';
# Initialize the left side as blank.

my $rightside = '';
# Initialize the right side as blank.

while (defined $line) {
# Until either of the input files is exhausted:

	$leftside = <$left>;
	# Identify the next left line.

	$rightside = <$right>;
	# Identify the next right line.

	if ((defined $leftside) && (defined $rightside)) {
	# If both exist:

		chomp $leftside;
		# Remove the trailing newline of the left line.

		chomp $rightside;
		# Remove the trailing newline of the right line.

		print $combo "$leftside\t$rightside\n";
		# Output the combined line.

	}

	else {
	# Otherwise, i.e. if at least 1 doesn’t exist:

		$line = undef;
		# Identify the process as complete.

	}

}

close $right;

close $left;

close $combo;
