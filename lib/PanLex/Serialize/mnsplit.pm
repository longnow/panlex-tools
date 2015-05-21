# Splits multi-meaning lines of a tagged source file, eliminating any duplicate
# output lines.
# Arguments:
#   col:    column that may contain multiple meanings.
#   delim:  meaning-delimitation tag. default '⫷mn⫸'.

package PanLex::Serialize::mnsplit;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/mnsplit/;

sub mnsplit {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my ($mncol, $delim);

    if (ref $args eq 'HASH') {
        $mncol    = $args->{col};
        $delim    = $args->{delim} // '⫷mn⫸';      
    } else {
        ($delim, $mncol) = @$args;
    }

    validate_col($mncol);

    my %line;

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $mncol not present in line" unless defined $col[$mncol];

        if (index($col[$mncol], $delim) < 0) {
        # If the potentially multimeaning column is one-meaning:

            unless (exists $line{$_}) {
            # If the line isn't a duplicate:

                $line{$_} = '';
                # Add it to the table of output lines.

                print $out $_, "\n";
                # Output it.
            }
        }

        else {
        # Otherwise, i.e. if the column is multimeaning:

            foreach my $mn (split /$delim/, $col[$mncol]) {
            # For each of its meaning segments:

                my @line = @col;
                # Identify its line's columns, with the multimeaning column unchanged.

                $line[$mncol] = $mn;
                # Replace the multimeaning column with the meaning segment.

                my $ln = join("\t", @line);
                # Identify the meaning's line.

                unless (exists $line{$ln}) {
                # If it isn't a duplicate:

                    $line{$ln} = '';
                    # Add it to the table of output lines.

                    print $out $ln, "\n";
                    # Output it.
                }
            }
        }
    }
}

1;