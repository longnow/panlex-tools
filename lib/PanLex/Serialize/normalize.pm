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
#   ap:       array of source IDs whose meanings are to be ignored 
#               in normalization; [] if none. default [].
#   log:      set to 1 to log normalize scores to normalize.json, 0 otherwise.
#               default: 0.
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
#   tagre:    regex identifying any tag. default '⫷[a-z:]+⫸'.

package PanLex::Serialize::normalize;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw/normalize/;

use PanLex::Client::Normalize;
use PanLex::Validation;
use PanLex::MungeJson;

use Unicode::Normalize;
use JSON;

sub normalize {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($excol, $uid, $min, $mindeg, $ap, $log, $failtag, $ignore, @propcols, $delim, $extag, $exptag, $tagre);
    
    if (ref $args eq 'HASH') {
        $excol      = $args->{col};
        $uid        = $args->{uid};
        $min        = $args->{min};
        $mindeg     = $args->{mindeg};
        $ap         = $args->{ap} // [];
        $log        = $args->{log} // 0;
        $failtag    = $args->{failtag} // $args->{dftag} // '⫷df⫸';
        $ignore     = $args->{ignore} // '';
        @propcols   = @{$args->{propcols} || []};
        $delim      = $args->{delim} // '';
        $extag      = $args->{extag} // '⫷ex⫸';
        $exptag     = $args->{exptag} // '⫷exp⫸';
        $tagre      = $args->{tagre} // '⫷[a-z:]+⫸';
    } else {
        ($tagre, $extag, $excol, $min, $mindeg, $uid, $exptag, $failtag, $delim) = @$args;
        $ignore = '';
        $log = 0;
    }

    my ($log_fh, $log_obj, $json);
    if ($log) {
        open $log_fh, '>:utf8', 'normalize.log' or die $!;
        $json = JSON->new->pretty->canonical;
    }

    validate_col($excol);
    validate_uid($uid);

    die "invalid min value: $min" unless valid_int($min) && $min >= 0;
    die "invalid mindeg value: $mindeg" unless $mindeg eq '' || (valid_int($mindeg) && $mindeg >= 0);
        
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
        # If the column containing proposed expressions isn’t among them, report the
        # error and quit.

        if (length $col[$excol]) {
        # If the column containing proposed expressions is nonblank:

            my @seg = ($col[$excol] =~ /($tagre.+?(?=$tagre|$))/g);
            # Identify the tagged items, each item including its tag, in it.

            foreach my $seg (@seg) {
            # For each of the tagged items:

                if (index($seg, $extag) == 0) {
                # If it is tagged as an expression:

                    foreach my $ex (PsList($seg, $lentag, $delim)) {
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
    }

    my $result = panlex_norm('ex', $uid, [keys %ex], 0, $ap);
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
        $result = panlex_norm('ex', $uid, [keys %ex], 1, $ap);
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

    foreach my $line (@line) {
    # For each line:

        my @col = split /\t/, $line, -1;
        # Identify its columns.

        if (length $col[$excol]) {
        # If the column containing proposed expressions is nonblank:

            my $excount = 0;
            my $failcount = 0;
            # Initialize counts of the number of expressions and normalization
            # failures in the column (needed for propcols).

            my @seg = ($col[$excol] =~ m/($tagre.+?(?=$tagre|$))/g);
            # Identify the tagged items, including tags, in the column.

            foreach my $seg (@seg) {
            # For each item:

                if (index($seg, $extag) == 0) {
                # If it is tagged as an expression:

                    $excount++;
                    # Count it as a single expression for the purpose of propcols.

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

                        if (length $failtag) {
                        # If proposed expressions not classifiable as expressions
                        # are to be converted to another tag:

                            $seg = "$failtag$seg";
                            # Prepend the tag to the concatenation.

                            $failcount++;
                            # Note the failure for the purpose of propcols.

                        }

                        else {
                        # Otherwise, i.e. if such proposed expressions are not
                        # to be converted to another tag:

                            $seg = "$exptag$seg";
                            # Prepend a pre-normalized expression tag to the
                            # concatenation.

                        }
                    }
                }
            }

            $col[$excol] = join('', @seg);
            # Identify the column with all expression reclassifications.

            if (@propcols and $excount == $failcount) {
            # If failures are to be propagated to other columns and every 
            # expression in the column failed normalization:

                foreach my $propcol (@propcols) {
                # For each column to which the conversion is to be propagated:

                    $col[$propcol] =~ s/$extag/$failtag/g;
                    # Convert all expression tags in it to the other tag.

                }
            }

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }

    if ($log) {
        print $log_fh munge_json($json->encode($log_obj)), "\n";
        close $log_fh;
    }
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
    # Identify the specified pseudo-list without its prefix.

    if (length $_[2] && $tt =~ /$_[2]/) {
    # If the pseudo-list is to be partitioned and contains at least 1 delimiter:

        @ex = split /$_[2]/, $tt;
        # Partition it and identify its elements.

    }

    else {
    # Otherwise, i.e. if the pseudo-list is not to be partitioned or it contains no
    # delimiter:

        @ex = ($tt);
        # Identify it as a 1-element list.

    }

    return @ex;
    # Return the list.

}

1;