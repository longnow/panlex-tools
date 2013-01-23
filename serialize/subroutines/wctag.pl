# Converts and tags word classifications in a tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: column containing word classifications.
#	3: word-classification tag.
#	4: metadatum tag.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w wctag.pl 'ces-epo-Procházka' 2 2 '⫷wc⫸' '⫷md:gram⫸'
# The -C63 switch ensures that argument 2 is treated as UTF8-encoded. If it is used within the
# script, it is “too late”.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.

open WC, '<:utf8', 'wc.txt';
# Open the wc file for reading.

open DICIN, '<:utf8', "$ARGV[0]-$ARGV[1].txt";
# Open the input file for reading.

open DICOUT, '>:utf8', ("$ARGV[0]-" . ($ARGV[1] + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my (@col, %wc, @wcmd);

while (<WC>) {
# For each line of the wc file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/);
	# Identify its columns.

	$wc{$col[0]} = $col[1];
	# Add it to the table of wc conversions.

}	

while (<DICIN>) {
# For each line of the input file:

	chomp;
	# Delete its trailing newline.

	@col = (split /\t/, $_, -1);
	# Identify its columns.

	if (exists $wc{$col[$ARGV[2]]}) {
	# If the content of the column containing word classifications is a convertible one:

		@wcmd = (split /:/, $wc{$col[$ARGV[2]]});
		# Identify the wc and the md values of its conversion.

		if (@wcmd == 1) {
		# If there is no md value:

			$col[$ARGV[2]] = "$ARGV[3]$wcmd[0]";
			# Convert the wc to a tagged wc.

		}

		elsif (@wcmd == 2) {
		# Otherwise, if there is an md value:

			if (length $wcmd[0]) {
			# If there is a wc value:

				$col[$ARGV[2]] = "$ARGV[3]$wcmd[0]$ARGV[4]$wcmd[1]";
				# Convert the wc to a wc and an md, each tagged.

			}

			else {
			# Otherwise, i.e. if there is no wc value:

				$col[$ARGV[2]] = "$ARGV[4]$wcmd[1]";
				# Convert the wc to a tagged md.

			}

		}

	}

	elsif (length $col[$ARGV[2]]) {
	# Otherwise, if the content of the column containing word classifications is
	# not blank:

		$col[$ARGV[2]] = "$ARGV[4]$col[$ARGV[2]]";
		# Convert the content to a tagged md.

	}

	print DICOUT ((join "\t", @col), "\n");
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
