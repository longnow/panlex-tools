# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing definitions.
#   dftag:  definition tag. default '⫷df⫸'.
#   delim:  inter-definition delimiter, or '' if none. default '‣'.

package PanLex::Serialize::dftag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw(dftag);

sub dftag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@dfcol, $dftag, $delim);

    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @dfcol    = @{$args->{cols}};
        $dftag    = $args->{dftag} // '⫷df⫸';
        $delim    = $args->{delim} // '‣';
    } else {
        ($dftag, @dfcol) = @$args;
        validate_cols(\@dfcol);
        $delim    = '';
    }
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@dfcol) {
        # For each definition column:

            die "column $i not present in line" unless defined $col[$i];

            if (length $col[$i]) {
            # If the column is not blank:

                if (length $delim) {

                    $col[$i] = join('', map { $dftag . $_ } split /$delim/, $col[$i]);
                    # Prefix a definition tag to each definition in the column.

                }

                else {

                    $col[$i] = $dftag . $col[$i];
                    # Prefix a definition tag to the column.

                }

            }

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;