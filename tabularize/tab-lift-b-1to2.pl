#!/usr/bin/env perl

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

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 1;
# Identify the input file's version.

#######################################################

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.txt";
# Open the input file for reading.

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my (%all, $i, $key, @seg);

while (<$in>) {
# For each line of the input file:

    chomp;
    # Delete its trailing newline.

    if (/⫷ex:(?:eng|cmn):/) {
    # If it includes a translation:

        s/^⫷mi:([^⫸]+)⫸⫷ex:cng:([^⫸]+)⫸⫷ex:cmn:([^⫸]+)⫸⫷ex:eng:([^⫸]+)⫸$/$1\t$2\t$3\t$4/;
        # If it has 1 cmn-003 and 1 eng-000 translation, convert it.

        @seg = split /\t/, $_, -1;
        # Identify its segments.

        foreach $i (2, 3) {
        # For each of segments 2 and 3:

            while ($seg[$i] =~ s/ {2,}(?![^()]*\))/‣/) {}
            # Replace all unparenthesized multiple spaces in it with synonym delimiters.

        }

        $seg[3] =~ s/s\.o\./someone/g;
        # Unabbreviate “someone” in segment 3.
            
        $seg[3] =~ s/\.{3}/ … /g;
        # Replace all triple periods in segment 3 with diareses.

        foreach $i (1 .. 3) {
        # For each of segments 1–3:

            $seg[$i] = (&Trim ($seg[$i]));
            # Trim spaces in it.

            $seg[$i] =~ s/ ?\([^()]+$//;
            # Delete any trailing substring beginning with an open parenthesis and not
            # closed.

            $seg[$i] =~ s/^(.+)!$/⫷wc:ijec⫸$1/;
            # Convert any trailing exclamation mark to a preposed wc specification.

        }

        $seg[3] =~ s/(?:^|‣)\K((?:to become|to be|to|become|be)) /⫷wc:verb⫸($1) /g;
        # In all expressions in segment 3 that begin with a verb particle or copula,
        # parenthesize it and prefix the expressions with wc specifications.

        $seg[3] =~ s/^CL \(([^()]+)\)$/$1⫷md:gram⫸classifier/;
        # If segment 3 is a classifier, convert it to an expression and a metadatum.

        $key = join("\t", @seg[1 .. 3]);
        # Identify a concatenation of segments 1–3.

        unless (exists $all{$key}) {
        # If that concatenation has not been encountered before:

            $all{$key} = '';
            # Add it to the table of concatenations.

            print $out join("\t", @seg), "\n";
            # Output the line.

        }

    }

}

close $in;
# Close the input file.

close $out;
# Close the output file.

# Trim
# Deletes leading, trailing, and extra spaces from the specified tab-delimited string.
# Argument:
#    0: string.

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

