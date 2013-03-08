# Retags word classifications in a tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2. input file's wc tag before its content.
#	3. input file's wc tag after its content.
#	4: output file's word-classification tag.
#	5: metadatum tag.
#	6+: columns containing word classifications.

# This script must be an argument to a command calling Perl, e.g.:
# /usr/bin/perl -C63 -w wcretag.pl 'ces-epo-Procházka' 2 '⫷wc:' '⫸' '⫷wc⫸' '⫷md:gram⫸' 1 2
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

my (@col, $col, $i, $md, %wc, @wcmd);

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

	foreach $i (@ARGV[6 .. $#ARGV]) {
	# For each column containing word classifications:

		while ($col[$i] =~ /$ARGV[2](.+?)$ARGV[3]/) {
		# As long as any remains unretagged:

			if (exists $wc{$1}) {
			# If the first one's content is convertible:

				@wcmd = (split /:/, $wc{$1});
				# Identify the wc and the md values of its conversion.

				if (@wcmd == 1) {
				# If there is no md value:

					$col[$i] =~ s/$ARGV[2].+?$ARGV[3]/$ARGV[4]$wcmd[0]/;
					# Retag the wc.

				}

				else {
				# Otherwise, i.e. if there is an md value:

					if (length $wcmd[0]) {
					# If there is a wc value:

						$col[$i] =~ s/$ARGV[2].+?$ARGV[3]/$ARGV[4]$wcmd[0]$ARGV[5]$wcmd[1]/;
						# Retag the wc.

					}

					else {
					# Otherwise, i.e. if there is no wc value:

						$col[$i] =~ s/$ARGV[2].+?$ARGV[3]/$ARGV[5]$wcmd[1]/;
						# Retag the wc.

					}

				}

			}

			else {
			# Otherwise, i.e. if the first one's content is not convertible:

				$md = $1;
				# Identify it.

				$col[$i] =~ s/$ARGV[2].+?$ARGV[3]/$ARGV[5]$md/;
				# Retag the wc.

			}

		}

	}

	print DICOUT ((join "\t", @col), "\n");
	# Output the line.

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.
