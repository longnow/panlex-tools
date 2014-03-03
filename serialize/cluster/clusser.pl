#!/usr/bin/env perl

# clusser.pl

# Converts a file it this format of to a final source file:
#
#                                                           Table "pc.excl20x"
# Column |     Type     | Modifiers | Storage  |               Description                                       
#--------+--------------+-----------+----------+-----------------------------------------------------
# cl     | smallint     | not null  | plain    | cluster
# uid    | character(7) | not null  | extended | UID of the language variety of an expression that
#                                              | has at least 1 meaning in the cluster
# tt     | text         | not null  | extended | text of the expression
# q      | integer      | not null  | plain    | sum of the estimated qualities of the sources of
#                                              | the expression’s meanings
#Indexes:
#    "excl20x_pkey" PRIMARY KEY, btree (cl, uid, tt)
#
# Additional documentation in clustab.pl describes the creation of such a table.
#
# Arguments:
#   0: basename of file to be converted. It extension must be “.txt”.

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

open my $outfh, '>:utf8', "$in-final.txt";
# Create or truncate the output file and open it for writing.

my @col;

my $cl= 0;
# Initialize the cluster as 0.

print $outfh ":\n1\nart-282\n";
# Output a full-text centrilingual file header declaring art-282 as the central
# language variety.

while (<$infh>) {
# For each line of the input file:

    chomp;
    # Delete its trailing newline.

    @col = (split /\t/, $_, -1);
    # Identify the line’s columns.

    if ($col[0] != $cl) {
    # If its cluster differs from that of the previous line:

        $cl = $col[0];
        # Make its cluster the current one.

        print $outfh ("\nex\n" . (substr "000$cl", -4) . "\n");
        # Output the expression in art-282.

    }

    print $outfh "ex\n$col[1]\n$col[2]\nmd\nq\n$col[3]\n";
    # Output the data other than the art-282 expression.

}

close $infh;
# Close the input file.

close $outfh;
# Close the input file.
