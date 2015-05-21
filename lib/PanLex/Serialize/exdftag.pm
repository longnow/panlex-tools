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
#   postre:   regex matching any post-tag character. default '[^⫷]'.
#   postwre:  regex matching any post-tag character that is not a space;
#               default '[^⫷ ]'.
#   prere:    regex matching a preposed annotation not to be counted, or '' if
#               none. default '⫷[^⫷⫸]+⫸'.

package PanLex::Serialize::exdftag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';

our @EXPORT = qw/exdftag/;

use PanLex::Validation;

sub exdftag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@exdfcol, $re, $subre, $tmc, $tmw, $extag, $dftag, $postre, $postwre, $prere);

    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @exdfcol  = @{$args->{cols}};
        $re       = $args->{re} // '';
        $subre    = $args->{subre} // '';
        $tmc      = $args->{maxchar} // '';
        $tmw      = $args->{maxword} // '';
        $extag    = $args->{extag} // '⫷ex⫸';
        $dftag    = $args->{dftag} // '⫷df⫸';
        $postre   = $args->{postre} // '[^⫷]';
        $postwre  = $args->{postwre} // '[^⫷ ]';
        $prere    = $args->{prere} // '⫷[^⫷⫸]+⫸';
    } else {
        ($extag, $postre, $postwre, $re, $dftag, $tmc, $tmw, $subre, $prere, @exdfcol) = @$args;
        validate_cols(\@exdfcol);
    }

    $tmc++ if $tmc;
    # Identify the character count of the shortest expression exceeding the maximum
    # character count, or blank if none.

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

            if (length $re) {
            # If there is a criterion for definitional substrings:

                while ($col[$i] =~ /($extag(?:$prere)?$postre*$re$postre*)/) {
                # As long as any expression in the column satisfies the criterion:

                    my ($df,$ex) = ($1,$1);
                    # Identify the first such expression and a definition identical to it.

                    $df =~ s/^$extag(?:$prere)?/$dftag/;
                    # In the definition, change the expression tag and any preposed annotation
                    # to a definition tag.

                    $ex =~ s/$re//g;
                    # In the expression, delete all definitional substrings.

                    $ex =~ s/ {2,}/ /g;
                    # In the expression, collapse any multiple spaces.

                    $ex =~ s/^$extag(?:$prere)?\K | $//g;
                    # In the expression, delete all initial and final spaces.

                    $ex = '' if (
                        ($ex eq $extag)
                        || ($tmc && ($ex =~ /^$extag(?:$prere)?+.{$tmc}/))
                        || ($tmw && ($ex =~ /^(?:[^ ]+ ){$tmw}/))
                        || ((length $subre) && ($ex =~ /^$extag(?:$prere)?$postre*$subre/))
                    );
                    # If the expression has become blank, exceeds a maximum count, or contains
                    # a prohibited character, delete the expression. (The possessive quantifier
                    # prohibits including a preposed annotation in the count.)

                    $col[$i] =~ s/$extag(?:$prere)?$postre*$re$postre*/$df$ex/;
                    # Replace the expression with the definition and the reduced expression.

                }
            }
            
            $col[$i] =~ s/$extag(?:$prere)?(${postre}{$tmc,})/$dftag$1/g
                if $tmc;
            # Convert every expression in the column that exceeds the maximum character
            # count, if there is one, to a definition, omitting any preposed annotation.

            $col[$i] =~ s/$extag(?:$prere)?((?:$postwre+ +){$tmw})/$dftag$1/g
                if $tmw;
            # Convert every expression in the column that exceeds a maximum word count,
            # if there is one, to a definition, omitting any preposed annotation.

            $col[$i] =~ s/$extag(?:$prere)?($postre*(?:$subre))/$dftag$1/g
                if length $subre;
            # Convert every expression containing a prohibited character, if there is any,
            # to a definition, omitting any preposed annotation.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;