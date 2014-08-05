### normtrim.pl
# Normalize the characters in the specified string according to the PanLex standard and
# trim leading and trailing spaces.

use utf8;
# Make Perl interpret the script as UTF-8. Calling script's invocation of
# this pragma does not apply to this script, which is imported with a
# “require” statement, i.e. via an “eval `cat trim.pl`” mechanism.

use Unicode::Normalize 'NFC';
# Import a function to normalize Unicode strings.

#### NormTrim
# Normalize the specified string according to the PanLex standard and trim leading
# and trailing spaces.
# Normalization:
# Convert the string to its normalization form C, then delete any characters with
# Other Unicode General Category properties (e.g., zero-width space), then replace
# and sequences of characters with Separator Unicode General Category properties with
# single spaces, then remove any leading and any trailing space, and then return the
# converted string.
# Trimming:
# Delete every space that immediately precedes any of the following: a standard meaning
# delimiter, a standard synonym delimiter, a tab, an opening tag bracket, a closing tag
# bracket, or the end of the string.
# Delete every space that immediately follows any of the following: a standard meaning
# delimiter, a standard synonym delimiter, a tab, a closing tag bracket, or the beginning
# of the string.
# Arguments:
#	0: a string.

sub NormTrim {

	my $ret = (&NFC ($_[0]));
	# Identify the normalization form C (canonical decomposition followed by canonical
	# composition) of the specified string. (The normalization form was changed from KC to K,
	# and so the function was changed from NFKC to NFC, on 2010/01/30 because it was judged that
	# tonal superscripts were legitimately distinct from numerals. Any other compatibility
	# decompositions to be retained can be implemented à la carte.)

	$ret =~ s/\p{C}+//g;
	# Delete any sequence of 1 or more characters in it with Other Unicode General Category
	# properties.

	@seg = (split /\t/, $ret, -1);
	# Identify its tab-delimited segments.

	foreach $i (0 .. $#seg) {
	# For each of them:

		$seg[$i] =~ s/\p{Z}+/ /g;
		# Replace any sequence of 1 or more characters in it with the Separator Unicode
		# General Category properties with a single space.

	}

	$ret = (join "\t", @seg);
	# Reidentify the string.

	$ret =~ s/ (?=[⁋‣\t⫷⫸]|$)//g;
	# Delete all trailing spaces in it.

	$ret =~ s/(?:^|[⁋‣\t⫸])\K //g;
	# Delete all leading spaces in it.

	return $ret;
	# Return the normalized string.

}

1;
