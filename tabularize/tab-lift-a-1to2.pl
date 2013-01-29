#!/usr/bin/env perl -w

# tab-lift-1to2.pl
# Finishes tabularizing a lift file.
# Requires adaptation to the structure of each file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $fnbase = 'aaa-bbb-Author';
# Identify the filename base.

my $ver = 1;
# Identify the input file’s version.

#######################################################

open DICIN, '<:encoding(utf8)', "$fnbase-$ver.txt";
# Open the input file for reading.

open DICOUT, '>:encoding(utf8)', ("$fnbase-" . ($ver + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my (%all, $key, @seg);

while (<DICIN>) {
# For each line of the input file:

	if (/⫷ex:eng:/) {
	# If it includes a translation:

		$_ = (&Trim ($_));
		# Trim spaces in it.

		s/⫷wc:(?:word|free root):/⫷wc:/;
		# If it has a word or free-root wc, simplify its value.

		s/^⫷mi:([^⫸]+)⫸⫷ex:pot:([^⫸]+)⫸⫷wc:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸$/$1\t$2\t$3\t$4/
		# If it has a wc and 1 eng-000 translation, convert it.
			|| s/^⫷mi:([^⫸]+)⫸⫷ex:pot:([^⫸]+)⫸⫷wc:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸$/$1\t$2\t$3\t$4⁋$5/
			# Otherwise, if it has a wc and 2 eng-000 translations, convert it.
			|| s/^⫷mi:([^⫸]+)⫸⫷ex:pot:([^⫸]+)⫸⫷wc:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸$/$1\t$2\t$3\t$4⁋$5⁋$6/
			# Otherwise, if it has a wc and 3 eng-000 translations, convert it.
			|| s/^⫷mi:([^⫸]+)⫸⫷ex:pot:([^⫸]+)⫸⫷wc:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸$/$1\t$2\t$3\t$4⁋$5⁋$6⁋$7/
			# Otherwise, if it has a wc and 4 eng-000 translations, convert it.
			|| s/^⫷mi:([^⫸]+)⫸⫷ex:pot:([^⫸]+)⫸⫷wc:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸$/$1\t$2\t$3\t$4⁋$5⁋$6⁋$7⁋$8/
			# Otherwise, if it has a wc and 5 eng-000 translations, convert it.
			|| s/^⫷mi:([^⫸]+)⫸⫷ex:pot:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸$/$1\t$2\t\t$3/;
			# Otherwise, if it has no wc and 1 eng-000 translation, convert it.

		s/s\.o\./someone/g;
		# Unabbreviate “someone”.
			
		s/s\.t\./something/g;
		# Unabbreviate “something”.

		@seg = (split /\t/, $_, -1);
		# Identify its segments.

		$seg[1] =~ s/, /‣/;
		# Replace any comma in segment 1 with a synonym delimiter.

		while ($seg[3] =~ s/(?:^|⁋|\))[^()]*\K, /⁋/) {}
		# Replace all commas in segment 3 not within parentheses with meaning delimiters.

		$seg[3] =~ s/(?:^|⁋)[^ \t]+ \Ksome(one|thing)(?=⁋|$)/(some$1)/g;
		# Parenthesize “someone” or “something” in segment 3 if it is the 2nd of a 2-word expression.

		$seg[3] =~ s/(?:^|⁋)\K(my|be a|be an) /($1) /g;
		# Parenthesize all initial instances of “my”, “be a”, and “be an” in segment 3.

		($seg[3] =~ s/ things(?=$|⁋)/ (things)/g) if ($seg[2] =~ /erb/);
		# If the pot-000 expression is verbal, parenthesize all final instances of “things”.

		$seg[2] =~ s/^bound root:(.+)$/$1:bound root/;
		# Move any bound-root qualification to the end of segment 2.

		unless ($seg[2] =~ s/^(Noun|Verb):/$1\t/) {
		# Convert any noun or verb qualification in segment 2 to a metadatum. If there was
		# none:

			$seg[2] .= "\t";
			# Append a blank column to segment 2.

		}

		$key = (join "\t", @seg[1 .. 3]);
		# Identify a concatenation of segments 1–3.

		unless (exists $all{$key}) {
		# If that concatenation has not been encountered before:

			$all{$key} = '';
			# Add it to the table of concatenations.

			print DICOUT (join "\t", @seg);
			# Output the line.

		}

	}

}

close DICIN;
# Close the input file.

close DICOUT;
# Close the output file.

# Trim
# Deletes leading, trailing, and extra spaces from the specified tab-delimited string.
# Argument:
#	0: string.

sub Trim {

	my $ret = $_[0];
	# Identify a copy of the specified string.

	$ret =~ s/ {2,}/ /g;
	# Collapse all multiple spaces in it.

	$ret =~ s/:\K | (?=⫸)//g;
	# Delete all leading and trailing spaces in it.

	return $ret;
	# Return it.

}

