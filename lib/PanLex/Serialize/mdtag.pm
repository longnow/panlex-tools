# Tags metadata in a tab-delimited source file.
# Arguments:
#   col:   column containing metadata.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.
#   delim: metadatum delimiter, or '' if none. default ''.

package PanLex::Serialize::mdtag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/mdtag/;

sub mdtag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my ($mdcol, $mdtag, $delim);
    
    if (ref $args eq 'HASH') {
        $mdcol    = $args->{col};
        $mdtag    = $args->{mdtag} // '⫷md:gram⫸';
        $delim    = $args->{delim} // '';
    } else {
        ($mdcol, $mdtag) = @$args;
        $delim = '';
    }
    validate_col($mdcol);

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $mdcol not present in line" unless defined $col[$mdcol];
        # If the specified column does not exist or has an undefined value, quit and
        # report the error.

        if (length $col[$mdcol]) {
        # If the column is not blank:

            if ($delim eq '') {
            # If there is no delimiter:

                $col[$mdcol] = "$mdtag$col[$mdcol]";
                # Prefix a metadatum tag to the column's content.
            } else {
            # Otherwise, i.e. if there is a delimiter:

                $col[$mdcol] = join('', map { "$mdtag$_" } split /$delim/, $col[$mdcol]);
                # Prefix a metadatum tag to each item in the column.
            }
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;