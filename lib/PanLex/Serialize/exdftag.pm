# Splits definitional expressions into reduced expressions and definitions in 
# a source file with already-tagged expressions and tags the added definitions.
# Arguments:
#   cols:     array of columns containing expressions that may contain 
#               definitional parts.
#   re:       regex matching a definitional part of an expression, or '' if none.
#   subre:    regex matching any substring forcing an expression to be
#               reclassified as a definition, or '' if none.
#   maxchar:  maximum character count permitted in an expression, or '' if none.
#               default ''. example: 25.
#   maxword:  maximum word count permitted in an expression, or '' if none.
#               default ''. example: 3.
#   extag:    expression tag. default '⫷ex⫸'.
#   dftag:    definition tag. default '⫷df⫸'.

package PanLex::Serialize::exdftag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::Util;

our @EXPORT = qw/exdftag/;

sub exdftag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@exdfcol, $re, $subre, $tmc, $tmw, $extag, $dftag);

    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @exdfcol  = @{$args->{cols}};
        $re       = $args->{re} // '';
        $subre    = $args->{subre} // '';
        $tmc      = $args->{maxchar} // '';
        $tmw      = $args->{maxword} // '';
        $extag    = $args->{extag} // '⫷ex⫸';
        $dftag    = $args->{dftag} // '⫷df⫸';
    } else {
        ($extag, undef, undef, $re, $dftag, $tmc, $tmw, $subre, undef, @exdfcol) = @$args;
        validate_cols(\@exdfcol);
    }

    $extag = validate_tag($extag);
    $dftag = validate_tag($dftag);

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@exdfcol) {
        # For each of them that may contain expressions with embedded definitions or
        # expressions classifiable as definitions:

            die "column $i not present in line" unless defined $col[$i];

            my $tags = parse_tags($col[$i]);
            # Identify a parsed representation of the column's tags.

            foreach my $ex (grep { tags_match($extag, $_) } @$tags) {
            # For every expression in the column:

                if (length $re && $ex->[2] =~ /$re/) {
                # If there is a criterion for definitional substrings and the expression
                # satisfies it:

                    my $df = [ $dftag->[0], $dftag->[1], $ex->[2] ];
                    # Identify a definition identical to the expression.

                    $ex->[2] =~ s/$re//g;
                    # In the expression, delete all definitional substrings.

                    $ex->[2] =~ s/ {2,}/ /g;
                    # In the expression, collapse any multiple spaces.

                    $ex->[2] =~ s/^ | $//g;
                    # In the expression, delete all initial and final spaces.

                    $ex->[0] = '' if (
                        $ex->[2] eq '' || 
                        ($tmc && length $ex->[2] > $tmc) ||
                        ($tmw && split(' ', $ex->[2]) > $tmw) ||
                        (length $subre && $ex->[2] =~ /$subre/)
                    );
                    # If the expression has become blank, exceeds a maximum count, or contains
                    # a prohibited character, delete the expression.

                    $ex = [ $df, $ex ];
                    # Replace the expression with the definition and the reduced expression.
                } else {

                    if (
                        ($tmc && length $ex->[2] > $tmc) ||
                        ($tmc && split(' ', $ex->[2]) > $tmw) ||
                        (length $subre && $ex->[2] =~ /$subre/)
                    ) {
                        ($ex->[0], $ex->[1]) = ($dftag->[0], $dftag->[1]);
                    }
                    # Convert every expression in the column that exceeds the maximum character
                    # count, if there is one, to a definition.
                    # Convert every expression in the column that exceeds a maximum word count,
                    # if there is one, to a definition.
                    # Convert every expression containing a prohibited character, if there is any,
                    # to a definition.

                }
            }

            $col[$i] = serialize_tags($tags);
            # Set the column value to the modified tags.
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;