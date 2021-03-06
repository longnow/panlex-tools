#!/usr/bin/env perl
# Parses an EXAsystem language file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# Make STDOUT and STDERR print in UTF-8.

#######################################################

my $BASENAME = 'Language';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<:bytes', "$BASENAME-$VERSION.dk" or die $!;
# Open the input file for reading.

my $ret = join('', <$in>);
# Initialize the result as a concatenation of all lines in the input file.

$ret = substr($ret, 106);
# Delete the first 106 characters from the result.

my @seg = ($ret =~ m/((?:.|\n){40})/g);
# Split the result into 40-character segments.

foreach my $seg (@seg) {
# For each of them:

    my @trio = (substr($seg, 0, 1), substr($seg, 1, 31), substr($seg, 31, 4));
    # Identify its length, lemma, and index.

    $trio[1] = substr($trio[1], 0, unpack('C', $trio[0]));
    # Shorten the lemma to its specified length.

    $trio[2] = unpack('N', $trio[2]);
    # Convert the index from the 32-bit string to a value.

    print $out join("\t", @trio[2, 1]), "\n";
    # Output the lemma and index, tab-delimited.

}

close $in;
# Close the input file.

close $out;
# Close the output file.
