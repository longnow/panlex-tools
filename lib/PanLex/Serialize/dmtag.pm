# Tags domain expressions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing metadata.
#   dmtag:  domain-expression tag. default '⫷dm⫸'.
#   delim:  inter-expression delimiter, or '' if none. default '‣'.

package PanLex::Serialize::dmtag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';

our @EXPORT = qw/dmtag/;

use PanLex::Validation;

sub dmtag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@dmcol, $dmtag, $delim);

    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @dmcol    = @{$args->{cols}};
        $dmtag    = $args->{dmtag} // '⫷dm⫸';
        $delim    = $args->{delim} // '‣';      
    } else {
        ($dmtag, $delim, @dmcol) = @$args;
        validate_cols(\@dmcol);
    }
    
    while (<$in>) {
    # For each line of the input file:

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@dmcol) {
        # For each domain-expression column:

            die "column $i not present in line" unless defined $col[$i];

            if (length $delim) {
            # If there is an inter-expression delimiter:

                $col[$i] =~ s/(^|$delim)(?!$|$delim)/$dmtag/g;
                # Prefix each element of the column's value with a domain-expression tag.
            }

            else {
            # Otherwise, i.e. if there is no inter-expression delimiter:

                $col[$i] = "$dmtag$col[$i]";
                # Prefix the column's value with a domain-expression tag.
            }
        }

        print $out join("\t", @col);
        # Output the line.
    }    
}

1;