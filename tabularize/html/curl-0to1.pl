#!/usr/bin/env perl

# tab-curl-0to1.pl
# Tabularizes an html-curl file.
# Requires adaptation to the structure of each file.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

my $all = join('', <$in>);
# Identify a concatenation of all lines of the input file.

$all =~ s/\n/ /g;
# Replace all newlines in the concatenation with spaces.

$all =~ s#<TR> <TD> <A NAME=[^<>]+><SPAN CLASS="ge">([^<>]+)</SPAN></A> </TD> <TD> <SPAN CLASS="ps">([^<>]+)</SPAN> </TD> <TD> <A HREF="[^"]+"><SPAN CLASS="fv">([^<>]+)</SPAN></A>(?: ?<SPAN CLASS="(?:sn|hm)">[^<>]+</SPAN>)* </TD> </TR>#\n¶$1\t$2\t$3\t\n#g;
# Convert all entries of one type in the concatenation to columns.

$all =~ s#<TR> <TD> · </TD> <TD> · </TD> <TD> <A HREF="[^"]+"><SPAN CLASS="fv">([^<>]+)</SPAN></A>(?: ?<SPAN CLASS="(?:sn|hm)">[^<>]+</SPAN>)* </TD> </TR>#\n¶.\t.\t$1\t\n#g;
# Convert all entries of another type in the concatenation to columns.

$all =~ s#<TR> <TD> · </TD> <TD> <SPAN CLASS="ps">([^<>]+)</SPAN> </TD> <TD> <A HREF="[^"]+"><SPAN CLASS="fv">([^<>]+)</SPAN></A>(?: ?<SPAN CLASS="(?:sn|hm)">[^<>]+</SPAN>)* </TD> </TR>#\n¶.\t$1\t$2\t\n#g;
# Convert all entries of another type in the concatenation to columns.

$all =~ s#<TR> <TD> <A NAME=[^<>]+><SPAN CLASS="ge">([^<>]+)</SPAN></A> </TD> <TD>  </TD> <TD> <A HREF="[^"]+"><SPAN CLASS="fv">([^<>]+)</SPAN></A>(?: ?<SPAN CLASS="(?:sn|hm)">[^<>]+</SPAN>)* </TD> </TR>#\n¶$1\t.\t$2\t\n#g;
# Convert all entries of another type in the concatenation to columns.

$all =~ s#<TR> <TD> <A NAME=[^<]+>?<SPAN CLASS="ge">([^<>]+ species: (?:[^,]+, )?)<SPAN CLASS="sc">([^<>]+)</SPAN>\??</SPAN></A> </TD> <TD> <SPAN CLASS="ps">([^<>]+)</SPAN> </TD> <TD> <A HREF="[^"]+"><SPAN CLASS="fv">([^<>]+)</SPAN></A>(?: ?<SPAN CLASS="(?:sn|hm)">[^<>]+</SPAN>)* </TD> </TR>#\n¶$1$2\t$3\t$4\t$2\n#g;
# Convert all entries of another type in the concatenation to columns.

print $out $all;
# Output the concatenation.

close $in;
# Close the input file.

close $out;
# Close the output file.
