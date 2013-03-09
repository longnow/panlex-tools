#!/usr/bin/env perl -w

# tab-curl-0to1.pl
# Tabularizes an html-curl file.
# Requires adaptation to the structure of each file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my $all = join('', <$in>);
# Identify a concatenation of all lines of the input file.

$all =~ s/\n/ /g;
# Replace all newlines in the concatenation with spaces.

$all =~ s#<b><FONT color=darkblue>([^<>]+)</FONT>:</b> +.+?> ([^<>]+) +</span></p>#\n¶$1\t$2\n#g;
# Convert all entries to columns.

print $out $all;
# Output the concatenation.

close $in;
# Close the input file.

close $out;
# Close the output file.
