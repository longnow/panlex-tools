#!/usr/bin/env perl

# reserialize.pl

# Converts a semitabular source file to a full-text varilingual source file.
# Arguments:
#   0: basename of file to be converted.
#   1: version suffix of file to be converted.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use open IO => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

my ($inb, $inv) = @ARGV;
# Identify the arguments.

my $in = "$inb-$inv.txt";
# Identify the name of the file to be converted.

(-r $in) || (die "could not find file $in");
# Verify that it exists and is readable.

(open my $infh, '<', $in) || (die $!);
# Open it for reading.

open my $outfh, '>', ("$inb-" . ($inv + 1) . '.txt');
# Create or truncate the output file and open it for writing.

print $outfh ":\n0\n";
# Output the file header.

my $ln = 0;
# Initialize the line index as 0.

while (<$infh>) {
# For each line of the input file:

    $ln++;
    # Increment the line index.

    chomp;
    # Delete its trailing newline.

    print $outfh "\n";
    # Output a newline preceding the line’s new entry.

    my @col = (split /\t/, $_, -1);
    # Ientify the line’s columns.

    shift @col;
    # Delete the first of them, i.e. the meaning ID.

    foreach my $col (@col) {
    # For each of the line’s remaining columns:

        my @pb = ($col =~ /^([^:]+):(.+)$/) || (die "Error parsing a column ($col) on line $ln\n");
        # Identify its first or only prefix and the remainder of it.

        if ($pb[0] =~ /^(?:mi|wc)$/) {
        # If the column is a meaning identifier or word classification and thus has only
        # one prefix:

            print $outfh "$pb[0]\n$pb[1]\n";
            # Output it.

        }

        else {
        # Otherwise, i.e. if the column has two prefixes:

            ((my @pb12 = ($pb[1] =~ /^([^:]+):(.+)$/)) == 2)
                || (die "Error identifying a second prefix on line $ln\n");
            # Identify the second prefix and the body.

            @pb[1, 2] = @pb12;
            # Revise the originally identified column remainder as these.

            if ($pb[0] =~ /^(?:dm|df|ex)$/) {
            # If the column is a domain specification, definition, or expression:

                print $outfh "$pb[0]\n$pb[1]\n$pb[2]\n";
                # Output it.

            }

            elsif ($pb[0] eq 'md') {
            # Otherwise, if the column is a metadatum component:

                if ($pb[1] eq 'vb') {
                # If it is the variable:

                    print $outfh "md\n$pb[2]\n";
                    # Output it.

                }

                else {
                # Otherwise, i.e. if it is the value:

                    print $outfh "$pb[2]\n";
                    # Output it.

                }

            }

            else {
            # Otherwise:

                die "Error in a column type on line $ln\n";
                # Report the error and quit.

            }

        }

    }

}

close $infh;
# Close the input file.

close $outfh;
# Close the output file.

1;
