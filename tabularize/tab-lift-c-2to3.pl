#!/usr/bin/env perl -w

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $BASENAME = 'sbe-spa-eng-Morse';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

my $lcs = 'sbe';
# Identify the source variety's lc per the input file.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

while (<$in>) {
# For each line of the input file:

	while (s%</text></form></lexical-unit><variant><form lang="$lcs"><text>([^<>]+)</text></form></variant>%‣$1</text></form></lexical-unit>%) {}
	# Convert all source-expression variants in it to synonyms.

	s%^<entry id="([^"]+)"><lexical-unit><form lang="$lcs"><text>([^<>]+)</text></form></lexical-unit>%$1\t$2\t%;
	# Convert its mi and source ex tt to columns.

	s%</entry>$%%;
	# Delete the closing entry tag in it.

	s%<grammatical-info value="([^"]+)"/>%⫷wcmd=$1⫸%g;
	# Shorten all wc-md specifications in it.

	s%<note><form lang="eng"><text>Tones: +([^<>]+)</text></form></note>%⫷tone=$1⫸%g;
	# Shorten all tone notes in it.

	s%<note type="dialect"><form lang="eng"><text>([^<>]+)</text></form></note>%⫷lvs=$1⫸%g;
	# Shorten all dialect notes in it.

	s%<note.+?</note>%%g;
	# Delete all other notes in it.

	s%<form lang="([^"]+)"><text>([^<>]+)</text></form>%⫷ex$1=$2⫸%g;
	# Shorten all translations in it.

	s%</?definition>%%g;
	# Delete all translation-enclosing tags in it.

	print $out;
	# Output it.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
