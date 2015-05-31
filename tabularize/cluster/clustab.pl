#!/usr/bin/env perl

# clustab.pl

# Converts a label-format output file from MCL (Markov Cluster Algorithm) to a
# columnar cluster file. The columnar cluster file is not a standard PanLex
# tabular file. It must be imported into PanLex as a table and used in the
# definition of a table with this structure:
#                              Table "pc.mncl20"
# Column |   Type   | Modifiers | Storage |           Description           
#--------+----------+-----------+---------+---------------------------------
# cl     | smallint | not null  | plain   | cluster
# mn     | integer  | not null  | plain   | a meaning in the cluster
# ap     | integer  | not null  | plain   | source of the meaning
# q      | smallint | not null  | plain   | estimated quality of the source
#Indexes:
#    "mncl20_pkey" PRIMARY KEY, btree (mn) CLUSTER
#
# That table is converted to tables of these structures with function pc.excl20w ():
#
#                                                          Table "pc.excl20"
# Column |   Type   | Modifiers | Storage |                   Description                                        
#--------+----------+-----------+---------+------------------------------------------------------
# cl     | smallint | not null  | plain   | cluster
# ex     | integer  | not null  | plain   | expression that has at least 1 meaning in the cluster
# q      | integer  | not null  | plain   | sum of the estimated qualities of the sources of
#                                         | the expression’s meanings in the cluster
#Indexes:
#    "excl20_pkey" PRIMARY KEY, btree (cl, ex) CLUSTER
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
# A table with the structure of pc.excl20x is copied to the local host and converted
# to a final source file with clusser.pl.
#
# Arguments:
#   0: basename of file to be converted. Its extension must be “.txt”.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use open IO => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

my ($in) = @ARGV;
# Identify the arguments.

my $inf = "$in.txt";
# Identify the name of the file to be converted.

(-r $inf) || (die "could not find file $inf");
# Verify that it exists and is readable.

(open my $infh, '<', $inf) || (die $!);
# Open it for reading.

open my $outfh, '>', "${in}t.txt";
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
