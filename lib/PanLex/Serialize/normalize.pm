# Normalizes expressions in a tagged source file.
# Arguments:
#   col:      column containing expressions to be normalized.
#   uid:      variety UID of expressions to be normalized.
#   min:      minimum score (0 or more) a proposed expression must have in order 
#               to be accepted outright as an expression. Every proposed 
#               expression with a lower (or no) score is to be replaced with the 
#               highest-scoring expression sharing its language variety and 
#               degradation, if any such expression has a higher score than it.
#   mindeg:   minimum score a proposed expression that is not accepted outright 
#               as an expression, or its replacement, must have in order to be
#               accepted as an expression. pass '' to disable replacement.
#   ui:       array of source group IDs whose meanings are to be ignored in
#               normalization; [] if none. default [].
#   log:      set to 1 to log normalize scores to normalize.json, 0 otherwise.
#               default 0.
#   failtag:  tag with which to retag proposed expressions not accepted as 
#               expressions and not having replacements accepted as expressions; 
#               '' (blank) if they are to be converted to pre-normalized 
#               expressions. default '⫷df⫸'.
#   ignore:   regex matching expressions to be ignored in normalization; or ''
#               (blank) if none. default ''.
#   propcols: array of columns to which the extag to failtag replacement should
#               be propagated when it takes place; [] if none. default [].
#   delim:    regex matching the synonym delimiter, if each proposed expression
#               containing such a delimiter is to be treated as a list of
#               synonymous proposed expressions and they are to be normalized if
#               and only if all expressions in the list are normalizable; or ''
#               (blank) if not. default ''. example: ', '.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.

package PanLex::Serialize::normalize;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IO => ':raw :encoding(utf8)';
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::Util;
use PanLex::Client::Normalize;
use PanLex::MungeJson;
use JSON;

our @EXPORT = qw/normalize/;

sub normalize {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($excol, $uid, $min, $mindeg, $ui, $log, $failtag, $ignore, @propcols, $delim, $extag, $exptag);
    
    if (ref $args eq 'HASH') {
        $excol      = $args->{col};
        $uid        = $args->{uid};
        $min        = $args->{min};
        $mindeg     = $args->{mindeg};
        $ui         = $args->{ui} // $args->{ap} // [];
        $log        = $args->{log} // 0;
        $failtag    = $args->{failtag} // $args->{dftag} // '⫷df⫸';
        $ignore     = $args->{ignore} // '';
        @propcols   = @{$args->{propcols} || []};
        $delim      = $args->{delim} // '';
        $extag      = $args->{extag} // '⫷ex⫸';
        $exptag     = $args->{exptag} // '⫷exp⫸';
    } else {
        (undef, $extag, $excol, $min, $mindeg, $uid, $exptag, $failtag, $delim) = @$args;
        $ignore = '';
        $log = 0;
    }

    validate_col($excol);
    validate_uid($uid);

    my $failtag_obj;
    $failtag_obj = validate_tag($failtag) if $failtag ne '';
    my $extag_obj = validate_tag($extag);
    $exptag = validate_tag($exptag);

    die "invalid min value: $min" unless valid_int($min) && $min >= 0;
    die "invalid mindeg value: $mindeg" unless $mindeg eq '' || (valid_int($mindeg) && $mindeg >= 0);
    
    my (%ex, %exok, $log_obj);

    my @lines = <$in>;
    # Identify a list of the lines of the input file.

    chomp @lines;
    # Delete their trailing newlines.

    foreach my $line (@lines) {
    # For each line:

        $line = [ split /\t/, $line, -1 ];
        # Identify its columns.

        die "column $excol not present in line" unless defined $line->[$excol];
        # If the column containing proposed expressions isn’t among them, report the
        # error and quit.

        $line->[$excol] = parse_tags($line->[$excol], 1);
        # Identify the tagged items in it.

        foreach my $tag (@{$line->[$excol]}) {
        # For each of the tagged items:

            my $subtag = ref $tag->[0] eq 'ARRAY' ? $tag->[1] : $tag;
            # Identify the tag or subtag that may contain an expression.

            if (tags_match($subtag, $extag_obj)) {
            # If it is tagged as an expression:

                die "don't know how to handle delimited expressions in complex tags"
                    if $subtag != $tag && $delim ne '';

                foreach my $ex (PsList($subtag->[2], $delim)) {
                # For the expression, or for each expression if it is a pseudo-list:

                    if (length $ignore && $ex =~ /$ignore/) {
                    # If the expression is to be ignored:

                        $exok{$ex} = '';
                        # Add it to the table of valid expressions, if not already in it.
                    }

                    else {
                    # Otherwise, i.e. if the expression is not to be ignored:

                        $ex{$ex} = '';
                        # Add it to the table of proposed expressions, if not already in it.
                    }
                }
            }
        }
    }

    my $result = panlex_norm('ex', $uid, [keys %ex], 0, $ui);
    $log_obj->{stage1} = $result if $log;

    foreach my $tt (keys %$result) {
        my $norm = $result->{$tt};

        # For each proposed expression that has a score and whose score is sufficient for
        # outright acceptance as an expression:
        if ($norm->{score} >= $min) {
            $exok{$tt} = delete $ex{$tt};
        }
    }

    my %ttto;

    if ($mindeg ne '') {
        $result = panlex_norm('ex', $uid, [keys %ex], 1, $ui);
        $log_obj->{stage2} = $result if $log;

        foreach my $tt (keys %$result) {
            # Identify the highest-scoring expression.
            $result->{$tt} = $result->{$tt}[0];
            my $norm = $result->{$tt};

            # For each proposed expression that is a highest-scoring expression in the variety with
            # its degradation and whose score is sufficient for acceptance as an expression:
            if ($norm->{score} >= $mindeg && defined $norm->{tt}) {
                if ($tt eq $norm->{tt}) {
                    $exok{$tt} = '';
                } else {
                    $ttto{$tt} = $norm->{tt};
                }
            }
        }
    }

    foreach my $line (@lines) {
    # For each line:

        my $excount = 0;
        my $failcount = 0;
        # Initialize counts of the number of expressions and normalization
        # failures in the column (needed for propcols).

        foreach my $tag (@{$line->[$excol]}) {
        # For each tag in the column containing proposed expressions:

            my $subtag = ref $tag->[0] eq 'ARRAY' ? $tag->[1] : $tag;
            # Identify the tag or subtag that may contain an expression.

            if (tags_match($subtag, $extag_obj)) {
            # If it is tagged as an expression:

                $excount++;
                # Count it as a single expression for the purpose of propcols.

                my $allok = 1;
                # Initialize the list's elements as all classifiable as
                # expressions.

                my @ex = PsList($subtag->[2], $delim);
                # Identify the expression, or a list of the expressions in it if
                # it is a pseudo-list.
                
                foreach my $ex (@ex) {
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

                if ($allok) {
                # If all elements of the list are classifiable as expressions with
                # or without replacement:

                    my @newtags;
                    # Identify a variable that will contain the rewritten tag(s).

                    foreach my $ex (@ex) {
                    # For each of them:

                        if (exists $exok{$ex}) {
                        # If it is classifiable as an expression without
                        # replacement:

                            push @newtags, [ $extag_obj->[0], $extag_obj->[1], $ex ];
                            # Append it, with an expression tag, to the tag list.
                        }

                        else {
                        # Otherwise, i.e. if it is classifiable as an
                        # expression only after replacement:

                            push @newtags, 
                                [ $exptag->[0], $exptag->[1], $ex ], 
                                [ $extag_obj->[0], $extag_obj->[1], $ttto{$ex} ];
                            # Append it, with a pre-normalized
                            # expression tag, and its replacement, with
                            # an expression tag, to the tag list.
                        }
                    }

                    if ($subtag == $tag) {
                    # If it is a simple tag:

                        $tag = \@newtags;
                        # Replace it with the new tag(s).

                    } else {
                    # Otherwise, i.e. if it is a complex tag:

                        splice @$tag, -1, 1, @newtags;
                        # Replace the last subtag with the new tag(s).

                    }
                }

                else {
                # Otherwise, i.e. if not all elements of the list are classifiable
                # as expressions with or without replacement:

                    my $newtag;
                    # Identify a variable that will contain the rewritten tag.

                    if (length $failtag) {
                    # If proposed expressions not classifiable as expressions
                    # are to be converted to another tag:

                        $newtag = [ $failtag_obj->[0], $failtag_obj->[1], $subtag->[2] ];
                        # Set the new tag to it with the tag indicating failure.

                        $failcount++;
                        # Note the failure for the purpose of propcols.

                    }

                    else {
                    # Otherwise, i.e. if such proposed expressions are to be 
                    # to be converted to pre-normalized expressions:

                        $newtag = [ $exptag->[0], $exptag->[1], $subtag->[2] ];
                        # Set the new tag to it with a pre-normalized expression tag.

                    }

                    if ($subtag == $tag || $newtag->[0] !~ /^[dm]pp$/) {
                    # If it is a simple tag, or a complex tag that is not to be
                    # changed into a property:

                        $tag = $newtag;
                        # Replace it with the new tag.

                    } else {
                    # Otherwise, i.e. if it is a complex tag to be changed into a property:

                        $tag->[1] = $newtag;
                        # Replace the last subtag with the new tag.

                        $tag->[0][0] = $newtag->[0];
                        # Propagate the tag change to the first subtag if it is a change
                        # to a property.
                    }
                }
            }
        }

        $line->[$excol] = serialize_tags($line->[$excol]);
        # Identify the rewritten column.

        if (@propcols and $excount == $failcount) {
        # If failures are to be propagated to other columns and every 
        # expression in the column failed normalization:

            foreach my $propcol (@propcols) {
            # For each column to which the conversion is to be propagated:

                $line->[$propcol] =~ s/$extag/$failtag/g;
                # Convert all expression tags in it to the other tag.

            }
        }

        print $out join("\t", @$line), "\n";
        # Output the line.
    }

    if ($log) {
        open my $log_fh, '>', "normalize${excol}.json" or die $!;
        print $log_fh munge_json(JSON->new->pretty->canonical->encode($log_obj)), "\n";
        close $log_fh;
    }
}

#### PsList
# Return a list of items in the specified prefixed pseudo-list.
# Arguments:
#    0: pseudo-list.
#    1: regular expression matching the pseudo-list delimiter, or blank if none.

sub PsList {
    my ($tt, $delim) = @_;

    if (length $delim) {
        return split /$delim/, $tt, -1;
    } else {
        return ($tt);
    }
}

1;