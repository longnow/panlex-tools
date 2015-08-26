# Copies tag(s) from a column to each tagged item in a list of columns, then 
#   deletes the column's tag(s).
# Arguments:
#   fromcol:  column containing tag(s) to be copied.
#   tocols:   array of columns containing tagged items.
#   delim:    intra-column tagged item delimiter. Default '‣'.

package PanLex::Serialize::copytag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/copytag/;

sub copytag {
    my ($in, $out, $args) = @_;

    validate_cols($args->{tocols});

    my $fromcol = $args->{fromcol};
    my @tocols = @{$args->{tocols}};
    my $delim = $args->{delim} // '‣';

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

            $col[$i] = join($delim, map { "$_$col[$fromcol]" } split $delim, $col[$i], -1)
                if length $col[$i];
            # Append the source column's text to each item of the column.
        }

        $col[$fromcol] = '';
        # Set the source column to an empty string.

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;