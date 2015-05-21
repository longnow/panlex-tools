# Normalizes expressions in a tagged source file by matching them against definitions.
# Arguments:
#   col:      column containing expressions to be normalized.
#   uid:      variety UID of expressions to be normalized.
#   mindeg:   minimum score a proposed expression or its replacement must have in 
#               order to be accepted as an expression.
#   ap:       array of source IDs whose meanings are to be ignored 
#               in normalization; [] if none. default [].
#   log:      set to 1 to log normalize scores to normalizedf.json, 0 otherwise.
#               default: 0.
#   ignore:   regex matching expressions to be ignored in normalization; or ''
#               (blank) if none. default ''.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.
#   tagre:    regex identifying any tag. default '⫷[a-z:]+⫸'.

package PanLex::Serialize::normalizedf;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';

our @EXPORT = qw/normalizedf/;

use PanLex::Client::Normalize;
use PanLex::Validation;
use PanLex::MungeJson;

use Unicode::Normalize;
use JSON;

sub normalizedf {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($excol, $uid, $mindeg, $ap, $log, $ignore, $extag, $exptag, $tagre);
    
    if (ref $args eq 'HASH') {
        $excol      = $args->{col};
        $uid        = $args->{uid};
        $mindeg     = $args->{mindeg};
        $ap         = $args->{ap} // [];
        $log        = $args->{log} // 0;
        $ignore     = $args->{ignore} // '';
        $extag      = $args->{extag} // '⫷ex⫸';
        $exptag     = $args->{exptag} // '⫷exp⫸';
        $tagre      = $args->{tagre} // '⫷[a-z:]+⫸';
    } else {
        die "invalid argument: you must pass a hashref";
    }

    my ($log_fh, $log_obj, $json);
    if ($log) {
        open $log_fh, '>:utf8', 'normalizedf.log' or die $!;
        $json = JSON->new->pretty->canonical;
    }

    validate_col($excol);
    validate_uid($uid);

    die "invalid mindeg value: $mindeg" unless valid_int($mindeg) && $mindeg >= 0;
        
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

                    my $ex = substr $seg, $lentag;

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

    my %ttto;

    my $result = panlex_norm('df', $uid, [keys %ex], 1, $ap);

    $log_obj = $result if $log;

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

    foreach my $line (@line) {
    # For each line:

        my @col = split /\t/, $line, -1;
        # Identify its columns.

        if (length $col[$excol]) {
        # If the column containing proposed expressions is nonblank:

            my @seg = ($col[$excol] =~ m/($tagre.+?(?=$tagre|$))/g);
            # Identify the tagged items, including tags, in it.

            foreach my $seg (@seg) {
            # For each item:

                if (index($seg, $extag) == 0) {
                # If it is tagged as an expression:

                    my $allok = 1;
                    # Initialize the list's elements as all classifiable as
                    # expressions.

                    my $ex = substr $seg, $lentag;

                    unless (exists $exok{$ex} || exists $ttto{$ex}) {
                    # If it is not classifiable as an expression without
                    # replacement or after being replaced:

                        $allok = 0;
                        # Identify the list as containing at least 1
                        # expression not classifiable as an expression.
                    }

                    $seg = '';
                    # Reinitialize the item as blank.

                    if ($allok) {
                    # If all elements of the list are classifiable as expressions with
                    # or without replacement:

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

                    else {
                    # Otherwise, i.e. if not all elements of the list are classifiable
                    # as expressions with or without replacement:

                        $seg .= "$extag$ex";
                        # Prepend an expression tag to the
                        # expression.

                    }
                }
            }

            $col[$excol] = join('', @seg);
            # Identify the column with all expression reclassifications.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }

    if ($log) {
        print $log_fh munge_json($json->encode($log_obj)), "\n";
        close $log_fh if $log;
    }
}

1;