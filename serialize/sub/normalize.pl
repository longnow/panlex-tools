# Normalizes expressions in a tagged source file.
# Arguments:
#   col:    column containing expressions to be normalized.
#   uid:    variety UID of expressions to be normalized.
#   min:    minimum score (0 or more) a proposed expression must have in order 
#             to be accepted outright as an expression. Every proposed expression
#             with a lower (or no) score is to be replaced with the highest-
#             scoring expression sharing its language variety and degradation, if
#             any such expression has a higher score than it.
#   mindeg: minimum score a proposed expression that is not accepted outright as
#             an expression, or its replacement, must have in order to be
#             accepted as an expression.
#   dftag:  definition tag, if proposed expressions not accepted as expressions 
#             and not having replacements accepted as expressions are to be
#             converted to definitions; '' (blank) if they are to be converted
#             to pre-normalized expressions. default '⫷df⫸'.
#   delim:  regular expression matching the synonym delimiter if each proposed
#             expression containing such a delimiter is to be treated as a list
#             of synonymous proposed expressions and they are to be normalized
#             if and only if all expressions in the list are normalizable; or ''
#             (blank) if not. default ''. example: ', '.
#   extag:  expression tag. default '⫷ex⫸'.
#   exptag: pre-normalized expression tag. default '⫷exp⫸'.
#   tagre:  regex identifying any tag. default '⫷[a-z:]+⫸'.

package PanLex::Serialize::normalize;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex;
use PanLex::Validation;

use Unicode::Normalize;
# Import the Unicode normalization module.

sub process {
    my ($in, $out, $args) = @_;
    
    validate_col($args->{col});
    validate_uid($args->{uid});

    my $excol   = $args->{col};
    my $uid     = $args->{uid};
    my $min     = $args->{min};
    my $mindeg  = $args->{mindeg};
    my $dftag   = defined $args->{dftag} ? $args->{dftag} : '⫷df⫸';
    my $delim   = defined $args->{delim} ? $args->{delim} : '';
    my $extag   = defined $args->{extag} ? $args->{extag} : '⫷ex⫸';
    my $exptag  = defined $args->{exptag} ? $args->{exptag} : '⫷exp⫸';
    my $tagre   = defined $args->{tagre} ? $args->{tagre} : '⫷[a-z:]+⫸';

    foreach my $score ($min, $mindeg) {
        die "invalid minimum score" unless valid_int($score) && $score >= 0;
    }
        
    my (%ex, %exok);

    my $lentag = length $extag;
    # Identify the length of the expression tag.

    my $done = 0;
    # Initialize the count of processed lines as 0.

    my @line = <$in>;
    # Identify a list of the lines of the input file.

    chomp @line;
    # Delete their trailing newlines.

    foreach my $line (@line) {
    # For each line:

        my @col = split /\t/, $line, -1;
        # Identify its columns.

        die "column $excol not present in line" unless defined $col[$excol];

        if (length $col[$excol]) {
        # If the column containing proposed expressions is nonblank:

            my @seg = ($col[$excol] =~ /($tagre.+?(?=$tagre|$))/go);
            # Identify the tagged items, including tags, in it.

            foreach my $seg (@seg) {
            # For each of them:

                if (index($seg, $extag) == 0) {
                # If it is tagged as an expression:

                    foreach my $ex (PsList($seg, $lentag, $delim)) {
                    # For the expression, or for each expression if it is a pseudo-list:

                        $ex{$ex} = '';
                        # Add it to the table of proposed expression texts, if not
                        # already in it.
                    }
                }
            }
        }
    }

    my $result = norm($uid, [keys %ex], 0);
        
    while (my ($tt,$norm) = each %$result) {
        # For each proposed expression that has a score and whose score is sufficient for
        # outright acceptance as an expression:
        if ($norm->{score} >= $min) {
            $exok{$tt} = delete $ex{$tt};
        }
    }

    $result = norm($uid, [keys %ex], 1);

    my %ttto;

    while (my ($tt,$norm) = each %$result) {
        # For each proposed expression that is a highest-scoring expression in the variety with
        # its degradation and whose score is sufficient for acceptance as an expression:
        if ($norm->{score} >= $mindeg && defined $norm->{ttNorm}) {
            if ($tt eq $norm->{ttNorm}) {
                $exok{$tt} = '';
            } else {
                $ttto{$tt} = $norm->{ttNorm};                    
            }
        }
    }

    foreach my $line (@line) {
    # For each line:

        my @col = split /\t/, $line, -1;
        # Identify its columns.

        if (length $col[$excol]) {
        # If the column containing proposed expressions is nonblank:

            my @seg = ($col[$excol] =~ m/($tagre.+?(?=$tagre|$))/go);
            # Identify the tagged items, including tags, in it.

            foreach my $seg (@seg) {
            # For each item:

                if (index($seg, $extag) == 0) {
                # If it is tagged as an expression:

                    my $allok = 1;
                    # Initialize the list's elements as all classifiable as
                    # expressions.

                    my @ex = PsList($seg, $lentag, $delim);
                    
                    foreach my $ex (@ex) {
                    # Identify the expression, or a list of the expressions in it if
                    # it is a pseudo-list.

                    # For each of them:

                        unless (exists $exok{$ex} || exists $ttto{$ex}) {
                        # If it is not classifiable as an expression without
                        # replacement or after being replaced:

                            $allok = 0;
                            # Identify the list as containing at least 1
                            # expression not classifiable as an expression.

                            last;
                            # Stop checking the expression(s) in the list.
                        }

                    }

                    $seg = '';
                    # Reinitialize the item as blank.

                    if ($allok) {
                    # If all elements of the list are classifiable as expressions with
                    # or without replacement:

                        foreach my $ex (@ex) {
                        # For each of them:

                            if (exists $exok{$ex}) {
                            # If it is classifiable as an expression without
                            # replacement:

                                $seg .= "$extag$ex";
                                # Append it, with an expression tag, to the
                                # item.
                            }

                            else {
                            # Otherwise, i.e. if it is classifiable as an
                            # expression only after replacement:

                                $seg .= "$exptag$ex$extag$ttto{$ex}";
                                # Append it, with a pre-normalized
                                # expression tag, and its replacement, with
                                # an expression tag, to the item.
                            }
                        }
                    }

                    else {
                    # Otherwise, i.e. if not all elements of the list are classifiable
                    # as expressions with or without replacement:

                        $seg = join($delim, @ex);
                        # Identify the concatenation of the list's elements, with
                        # the specified delimiter if any, i.e. the original item
                        # without its expression tag.

                        if (length $dftag) {
                        # If proposed expressions not classifiable as expressions
                        # are to be converted to definitions:

                            $seg = "$dftag$seg";
                            # Prepend a definition tag to the concatenation.
                        }

                        else {
                        # Otherwise, i.e. if such proposed expressions are not
                        # to be converted to definitions:

                            $seg = "$exptag$seg";
                            # Prepend a pre-normalized expression tag to the
                            # concatenation.
                        }
                    }
                }
            }

            $col[$excol] = join('', @seg);
            # Identify the column with all expression reclassifications.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }
}

#### norm
# Iteratively query the PanLex api at /norm and return the results.
# Arguments:
#   0: variety UID.
#   1: arrayref containing expression texts.
#   2: degrade parameter (boolean).

sub norm {
    my ($uid, $tt, $degrade) = @_;
    my $result = {};
        
    for (my $i = 0; $i < @$tt; $i += $PanLex::ARRAY_MAX) {
        my $last = $i + $PanLex::ARRAY_MAX - 1;
        $last = $#{$tt} if $last > $#{$tt};
        
        # get the next set of results.
        my $this_result = panlex_query("/norm/$uid", { 
            tt => [@{$tt}[$i .. $last]], 
            degrade => $degrade,
            cache => 0 
        });
                
        # merge with the previous results, if any.
        $result = { %$result, %{$this_result->{norm}} };
    }
    
    return $result;
}


#### PsList
# Return a list of items in the specified prefixed pseudo-list.
# Arguments:
#    0: pseudo-list.
#    1: length of its prefix.
#    2: regular expression matching the pseudo-list delimiter, or blank if none.

sub PsList {

    my @ex;

    my $tt  = substr $_[0], $_[1];
    # Identify the specified pseudo-list without its tag.

    if (length $_[2] && $tt =~ /$_[2]/) {
    # If expressions are to be classified as single or pseudo-list
    # and it contains a pseudo-list delimiter:

        @ex = split /$_[2]/, $tt;
        # Identify the expressions in the pseudo-list.
    }

    else {
    # Otherwise, i.e. if expressions are not to be classified as
    # single or pseudo-list or they are but it contains no
    # pseudo-list delimiter:

        @ex = ($tt);
        # Identify a list of the sole expression.
    }

    return @ex;
    # Return a list
}

1;