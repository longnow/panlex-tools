# Copies tagged denotation classifications or properties from a column to after each 
#   expression (standardly tagged) in a list of columns, then sets the column to ''.
# Arguments:
#   fromcol:  column containing tag(s) to be copied.
#   tocols:   array of columns containing tagged items.

package PanLex::Serialize::copydntag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/copydntag/;

sub copydntag {
    my ($in, $out, $args) = @_;

    validate_cols($args->{tocols});

    my $fromcol = $args->{fromcol};
    my @tocols = @{$args->{tocols}};

    validate_col($fromcol);
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $fromcol not present in line" unless defined $col[$fromcol];

        foreach my $i (@tocols) {
        # For each destination column:

            die "column $i not present in line" unless defined $col[$i];

            $col[$i] =~ s/(⫷ex⫸[^⫷]+)/$1$col[$fromcol]/g
                if length $col[$i];
            # Append the source column's text to each expression in the column.
        }

        $col[$fromcol] = '';
        # Set the source column to an empty string.

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;