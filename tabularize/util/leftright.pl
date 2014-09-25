#!/usr/bin/env perl

# Combines two files as the left and right columns of a new file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

open my $combo, '>:encoding(utf8)', $ARGV[2];

open my $left, '<:encoding(utf8)', $ARGV[0];

open my $right, '<:encoding(utf8)', $ARGV[1];

my $line = '';
# Initialize the line as blank.

my $left = '';
# Initialize the left side as blank.

my $right = '';
# Initialize the right side as blank.

foreach my $i (0, 1, 2) {
# 3 times:

	<$left>;
	<$right>;
	# Discard the input files’ lines.

}

while (defined $line) {
# Until either of the input files is exhausted:

	$left = <$left>;
	# Identify the next left line.

	$right = <$right>;
	# Identify the next right line.

	if ((defined $left) && (defined $right)) {
	# If both exist:

		chomp $left;
		# Remove the trailing newline of the left line.

		chomp $right;
		# Remove the trailing newline of the right line.

		my @col = ((split /\t/, $left, 4), (split /\t/, $right));
		# Identify the lines’ columns.

		print $combo ((join "\t", @col[0, 1, 4, 9, 2, 3]) . "\n");
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
