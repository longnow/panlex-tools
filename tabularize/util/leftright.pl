#!/usr/bin/perl -w

# Combines two files as the left and right columns of a new file.

open LEFT, 'leftfile.txt';

open RIGHT, 'rightfile.txt';

open COMBO, '>combinedfile.txt';

my $line = '';
# Initialize the line as blank.

my $left = '';
# Initialize the left side as blank.

my $right = '';
# Initialize the right side as blank.

my (@col, $i);

foreach $i (0, 1, 2) {
# 3 times:

	<LEFT>;
	<RIGHT>;
	# Discard the input files’ lines.

}

while (defined $line) {
# Until either of the input files is exhausted:

	$left = <LEFT>;
	# Identify the next left line.

	$right = <RIGHT>;
	# Identify the next right line.

	if ((defined $left) && (defined $right)) {
	# If both exist:

		chomp $left;
		# Remove the trailing newline of the left line.

		chomp $right;
		# Remove the trailing newline of the right line.

		@col = ((split /\t/, $left, 4), (split /\t/, $right));
		# Identify the lines’ columns.

		print COMBO ((join "\t", @col[0, 1, 4, 9, 2, 3]) . "\n");
		# Output the combined line.

	}

	else {
	# Otherwise, i.e. if at least 1 doesn’t exist:

		$line = undef;
		# Identify the process as complete.

	}

}

close LEFT;

close RIGHT;

close COMBO;
