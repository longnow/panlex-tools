#!/usr/bin/env perl

# reserialize.pl

# Converts a semitabular source file to a tabular source file.
# Arguments:
#   0: basename of file to be converted.
#   1: version suffix of file to be converted.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

my ($inb, $inv) = @ARGV;
# Identify the arguments.

my $in = "$inb-$inv.txt";
# Identify the name of the file to be converted.

(-r $in) || (die "could not find file $in");
# Verify that it exists and is readable.

(open my $infh, '<:utf8', $in) || (die $!);
# Open it for reading.

open my $outfh, '>:utf8', ("$inb-" . ($inv + 1) . '.txt');
# Create or truncate the output file and open it for writing.

my $ln = 0;
# Initialize the line index as 0.

my (@col, $col, %col, $uid, @pf);

while (<$infh>) {
# For each line of the input file:

    $ln++;
    # Increment the line index.

    chomp;
    # Delete its trailing newline.

    @col = (split /\t/, $_, -1);
    # Identify the line’s columns.

    shift @col;
    # Delete the first of them, i.e. the meaning ID.

    foreach $col (@col) {
    # For each of the line’s remaining columns:

        (@pf = ($col =~ /^(dm|df|ex):([a-z]{3}-[0-9]{3}):/))
            || (@pf = ($col =~ /^(mi|wc|md):/))
            || (die "Error getting the prefix(es) of “$col” on line $ln\n");
        # Identify its prefix(es) on which the column requirements for the output file
        # depend.

        if ($pf[0] eq 'ex') {
        # If the column is an expression:

            $uid = $pf[1];
            # Identify its language variety.

            $col{"ex:$uid"} = "3-$uid-0";
            # Add a column for expressions in that language variety and the column’s
            # proto-index to the table of required columns, if not already in it.

        }

        elsif ($pf[0] eq 'dm') {
        # Otherwise, if the column is a domain specification:

            $col{"dm:$pf[1]"} = "1-$pf[1]";
            # Add a column for domain specifications in its language variety and the
            # column’s proto-index to the table of required columns, if not already in it.

        }

        elsif ($pf[0] eq 'df') {
        # Otherwise, if the column is a definition:

            $col{"df:$pf[1]"} = "2-$pf[1]";
            # Add a column for definitions in its language variety and the column’s
            # proto-index to the table of required columns, if not already in it.

        }

        elsif ($pf[0] eq 'mi') {
        # Otherwise, if the column is a meaning identifier:

            $col{mi} = '0';
            # Add a column for meaning identifiers and the column’s proto-index to the
            # table of required columns, if not already in it.

        }

        elsif (($pf[0] ne 'wc') && ($pf[0] ne 'md')) {
        # Otherwise, if the column is neither a word classification nor a metadatum:

            die "Error in a column type on line $ln\n";
            # Report the error and quit.

        }

    }

}

close $infh;
# Close the input file.

my (@hd, %ix, $ix);

$col = 0;
# Initialize the index as 0.

my @ix = (sort (values %col));
# Identify the proto-indices in the table of required columns, sorted.

foreach $ix (@ix) {
# For each of them:

    $ix{$ix} = $col++;
    # Add it and the corresponding index to the table of column indices and increment
    # the index.

}

foreach $col (keys %col) {
# For each required column:

    $col{$col} = $ix{$col{$col}};
    # Replace its proto-index with its index in the table of required columns.

    $hd[$col{$col}] = $col;
    # Populate its column in the output file header with its descriptor.

}

print $outfh ((join "\t", @hd) . "\n");
# Output the header line of the output file.

(open $infh, '<:utf8', $in) || (die $!);
# Open the input file again for reading.

my ($excol, @out, @pfbd);

while (<$infh>) {
# For each line of the input file:

    @out = (('') x $col);
    # Initialize its output columns as blank.

    chomp;
    # Delete its trailing newline.

    @col = (split /\t/, $_, -1);
    # Identify the line’s columns.

    shift @col;
    # Delete the first of them, i.e. the meaning ID.

    foreach $col (@col) {
    # For each of the line’s remaining columns:

        (@pfbd = ($col =~ /^(dm|df|ex|md):([^:]+):(.+)$/)) || (@pfbd = ($col =~ /^(mi|wc):(.+)$/))
            || (die "Error getting the prefix(es) and body of “$col” on line $ln\n");
        # Identify its prefix(es) on which the column assignments depend and the body.

        if ($pfbd[0] eq 'ex') {
        # If the column is an expression:

            $uid = $pfbd[1];
            # Identify its language variety.

            $excol = $col{"ex:$uid"};
            # Identify its output column index.

            $out[$excol] .= (((length $out[$excol]) ? '‣' : '') . $pfbd[2]);
            # Append its body to its output column, prefixed by a synonym delimiter if
            # its output column is not blank.

        }

        elsif ($pfbd[0] eq 'dm') {
        # Otherwise, if the column is a domain specification:

            $out[$col{"dm:$pfbd[1]"}]
                .= (((length $out[$col{"dm:$pfbd[1]"}]) ? '‣' : '') . $pfbd[2]);
            # Append its body to its output column, prefixed by a synonym delimiter if
            # its output column is not blank.

        }

        elsif ($pfbd[0] eq 'df') {
        # Otherwise, if the column is a definition:

            $out[$col{"df:$pfbd[1]"}]
                .= (((length $out[$col{"df:$pfbd[1]"}]) ? '—' : '') . $pfbd[2]);
            # Append its body to its output column, prefixed by an em dash if
            # its output column is not blank.

        }

        elsif ($pfbd[0] eq 'mi') {
        # Otherwise, if the column is a meaning identifier:

            $out[$col{mi}] = $pfbd[1];
            # Populate its output column with its body.

        }

        elsif ($pfbd[0] eq 'wc') {
        # Otherwise, if the column is a word classification:

            $out[$excol] .= "⫷wc⫸$pfbd[1]";
            # Append a standard word-classification tag and the column’s body to the
            # output column of the preceding expression.

        }

        elsif (($pfbd[0] eq 'md') && ($pfbd[1] eq 'vb')) {
        # Otherwise, if the column is a metadatum variable:

            $out[$excol] .= "⫷md:$pfbd[2]⫸";
            # Append a standard metadatum tag specifying the column’s body as the
            # variable to the output column of the preceding expression.

        }

        elsif (($pfbd[0] eq 'md') && ($pfbd[1] eq 'vl')) {
        # Otherwise, if the column is a metadatum value:

            $out[$excol] .= $pfbd[2];
            # Append its body to the output column of the preceding expression.

        }

    }

    print $outfh ((join "\t", @out) . "\n");
    # Output the line.

}

close $infh;
# Close the input file.

close $outfh;
# Close the output file.

1;
