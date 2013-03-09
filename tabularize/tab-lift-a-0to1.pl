#!/usr/bin/env perl -w

# tab-lift-0to1.pl
# Starts tabularizing a lift file.
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

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.xml";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my $all = join('', <$in>);
# Identify the entire content of the input file.

$all =~ s/\n */ /g;
# Replace all newlines and subsequent leading spaces in it with single spaces.

$all =~ s#<entry id="([^"]+)">#\n⁋\t⫷mi:$1⫸#g;
# Convert all entry start tags with meaning identifiers in it and precede
# them with newlines.

$all =~ s#</entry> </#</entry>\n</#;
# Append a newline to the final entry.

$all =~ s#<note.+?</note>##g;
# Delete all notes in it (domains, but highly nonlemmatic).

$all =~ s#<example.+?</example>##g;
# Delete all examples in it.

$all =~ s#<form lang="([^"]+)"> <text>([^<>]+)</text> </form>#⫷ex:$1:$2⫸#g;
# Convert all language-typed source and target expressions in it.

$all =~ s#<grammatical-info value="([^"]+)"/>#⫷wc:$1⫸#g;
# Convert all word classifications in it.

$all =~ s/⫸[^⫷\n]+⫷/⫸⫷/g;
# Delete all content between converted items in it.

$all =~ s/^[^⫷\n]+⫷/⫷/mg;
# Delete all content before converted items in it.

$all =~ s/⫸[^⫷\n]+$/⫸/mg;
# Delete all content after converted items in it.

$all =~ s/\n{2,}/\n/g;
# Collapse all multiple newlines in it.

print $out $all;
# Output it.

close $in;
# Close the input file.

close $out;
# Close the output file.
