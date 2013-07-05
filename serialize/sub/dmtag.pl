# Tags domain expressions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing metadata.
#   dmtag:  domain-expression tag. default '⫷dm⫸'.
#   delim:  inter-expression delimiter, or '' if none. default '‣'.

package PanLex::Serialize::dmtag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub process {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@dmcol, $dmtag, $delim);

    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @dmcol    = @{$args->{cols}};
        $dmtag    = defined $args->{dmtag} ? $args->{dmtag} : '⫷dm⫸';
        $delim    = defined $args->{delim} ? $args->{delim} : '‣';      
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

                $col[$i] =~ s/(^|$delim)(?!$|$delim)/$dmtag/og;
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