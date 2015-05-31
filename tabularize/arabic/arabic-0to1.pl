#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open ':raw:encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

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
