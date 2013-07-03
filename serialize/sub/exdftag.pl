# Splits definitional expressions into reduced expressions and definitions in a source file with
# already-tagged expressions and tags the added definitions.
# Arguments:
#    0: expression tag in file.
#    1: regular expression matching any post-tag character.
#    2: regular expression matching any post-tag character that is not a space.
#    3: regular expression matching a definitional part of an expression.
#    4: definition tag to be used on definitions.
#    5: maximum character count permitted in an expression, or blank if none.
#    6: maximum word count permitted in an expression, or blank if none.
#    7: regular expression matching any substring forcing an expression to be
#        reclassified as a definition, or blank if none.
#    8: regular expression matching a preposed annotation not to be counted,
#        or blank if none.
#    9+: columns containing expressions that may contain definitional parts.

package PanLex::Serialize::exdftag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub process {
    my ($in, $out, $args) = @_;

    validate_hash($args);
    validate_cols($args->{cols});

    my @exdfcol = @{$args->{cols}};
    my $re      = defined $args->{re} ? $args->{re} : '';
    my $subre   = defined $args->{subre} ? $args->{subre} : '';
    my $tmc     = defined $args->{maxchar} ? $args->{maxchar} : '';
    my $tmw     = defined $args->{maxword} ? $args->{maxword} : '';
    my $extag   = defined $args->{extag} ? $args->{extag} : '⫷ex⫸';
    my $dftag   = defined $args->{dftag} ? $args->{dftag} : '⫷df⫸';
    my $postre  = defined $args->{postre} ? $args->{postre} : '[^⫷]';
    my $postwre = defined $args->{postwre} ? $args->{postwre} : '[^⫷ ]';
    my $prere   = defined $args->{prere} ? $args->{prere} : '⫷[^⫷⫸]+⫸';

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

                while ($col[$i] =~ /($extag$postre*$re$postre*)/o) {
                # As long as any expression in the column satisfies the criterion:

                    my ($df,$ex) = ($1,$1);
                    # Identify the expression and a definition identical to it.

                    $df =~ s/^$extag(?:$prere)?/$dftag/o;
                    # In the definition, change the expression tag and any preposed annotation
                    # to a definition tag.

                    $ex =~ s/$re//og;
                    # In the expression, delete all definitional substrings.

                    $ex =~ s/ {2,}/ /g;
                    # In the expression, collapse any multiple spaces.

                    $ex =~ s/^$extag(?:$prere)?\K | $//og;
                    # In the expression, delete all initial and final spaces.

                    $ex = '' if
                        $ex eq $extag
                        || ($tmc && $ex =~ /^$extag(?:$prere)?+.{$tmc}/o)
                        || ($tmw && $ex =~ /^(?:[^ ]+ ){$tmw}/o)
                        || (length $subre && $ex =~ /^$extag(?:$prere)?$postre*$subre/)
                    ;
                    # If the expression has become blank, exceeds a maximum count, or contains
                    # a prohibited character, delete the expression. (The possessive quantifier
                    # prohibits including a preposed annotation in the count.)

                    $col[$i] =~ s/$extag$postre*$re$postre*/$df$ex/o;
                    # Replace the expression with the definition and the reduced expression.
                }
            }

            $col[$i] =~ s/$extag(?:$prere)?(${postre}{$tmc,})/$dftag$1/og
                if $tmc;
            # Convert every expression in the column that exceeds the maximum character
            # count, if there is one, to a definition, omitting any preposed annotation.

            $col[$i] =~ s/$extag(?:$prere)?((?:$postwre+ ){$tmw})/$dftag$1/og
                if $tmw;
            # Convert every expression in the column that exceeds a maximum word count,
            # if there is one, to a definition, omitting any preposed annotation.

            $col[$i] =~ s/$extag(?:$prere)?($postre*(?:$subre))/$dftag$1/og
                if length $subre;
            # Convert every expression containing a prohibited character, if there is any,
            # to a definition, omitting any preposed annotation.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;