#!/usr/bin/env perl

# clustab.pl

# Converts a label-format output file from MCL (Markov Cluster Algorithm) to a
# columnar cluster file. The columnar cluster file is not a standard PanLex
# tabular file. It is serializable with clusser.pl.
# Arguments:
#   0: basename of file to be converted. Its extension must be “.txt”.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

my ($in) = @ARGV;
# Identify the arguments.

my $inf = "$in.txt";
# Identify the name of the file to be converted.

(-r $inf) || (die "could not find file $inf");
# Verify that it exists and is readable.

(open my $infh, '<:utf8', $inf) || (die $!);
# Open it for reading.

open my $outfh, '>:utf8', "${in}t.txt";
# Create or truncate the output file and open it for writing.

my $ln = 0;
# Initialize the line index as 0.

my (@col, $col);

while (<$infh>) {
# For each line of the input file:

    $ln++;
    # Increment the line index.

    chomp;
    # Delete its trailing newline.

    @col = (split /\t/, $_, -1);
    # Identify the line’s columns.

    foreach $col (@col) {
    # For each of them:

        print $outfh "$ln\t$col\n";
        # Output the line index and it.

    }

}

close $infh;
# Close the input file.

close $outfh;
# Close the input file.
