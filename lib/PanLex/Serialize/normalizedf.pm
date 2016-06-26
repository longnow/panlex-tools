# Normalizes expressions in a tagged source file by matching them against definitions.
# Arguments:
#   col:      column containing expressions to be normalized.
#   uid:      variety UID of expressions to be normalized.
#   mindeg:   minimum score a proposed expression or its replacement must have in 
#               order to be accepted as an expression.
#   strict:   set to 1 to only accept replacements differing in parentheses, 0
#               to accept all replacements. default 1.
#   ui:       array of source group IDs whose meanings are to be ignored in
#               normalization; [] if none. default [].
#   log:      set to 1 to log normalize scores to normalizedf.json, 0 otherwise.
#               default 1.
#   ignore:   regex matching expressions to be ignored in normalization; or ''
#               (blank) if none. default ''.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.

package PanLex::Serialize::normalizedf;
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

our @EXPORT = qw/normalizedf/;

sub normalizedf {
    my ($in, $out, $args) = @_;
    
    my $excol   = $args->{col};
    my $uid     = $args->{uid};
    my $mindeg  = $args->{mindeg};
    my $ui      = $args->{ui} // $args->{ap} // [];
    my $strict  = $args->{strict} // 1;
    my $log     = $args->{log} // 1;
    my $ignore  = $args->{ignore} // '';
    my $extag   = $args->{extag} // '⫷ex⫸';
    my $exptag  = $args->{exptag} // '⫷exp⫸';

    validate_col($excol);
    validate_uid($uid);

    $extag = validate_tag($extag);
    $exptag = validate_tag($exptag);

    die "invalid mindeg value: $mindeg" unless valid_int($mindeg) && $mindeg >= 0;
        
    my (%ex, %exok, $log_obj);

    my $lentag = length $extag;
    # Identify the length of the expression tag.

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

        $line->[$excol] = parse_tags($line->[$excol]);
        # Identify an array of references to the tag types, UIDs, and contents of
        # the tagged items in it.

        foreach my $tag (@{$line->[$excol]}) {
        # For each of the tagged items:

            if (tags_match($tag, $extag)) {
            # If it is tagged as an expression:

                my $ex = $tag->[2];
                # Identify its text.

                if (length $ignore && $ex =~ /$ignore/) {
                # If there is a criterion for texts to be ignored and it satisfies the criterion:

                    $exok{$ex} = '';
                    # Add it to the table of valid expression texts, if not already in it.
                }

                else {
                # Otherwise, i.e. if the text is not to be ignored:

                    $ex{$ex} = '';
                    # Add it to the table of proposed expression texts, if not already in it.
                }
            }
        }
    }

    my %ttto;

    my $result = panlex_norm('df', $uid, [keys %ex], 1, $ui);
    # Identify a reference to a table whose keys are the proposed expression texts and whose
    # values are df-type “norm” objects with “degrade” true, as defined by the PanLex API. Each “norm”
    # object is an array of score-text pairs, ordered from highest to lowest score, containing the
    # score of a definition text with matching degradation and the definition text itself.

    $log_obj = $result if $log;
    # Log the table if logging is being performed.

    foreach my $tt (keys %$result) {
    # For each proposed expression text:

        $result->{$tt} = $result->{$tt}[0];
        # Discard all but its first (i.e. highest-scoring) score-text pair.

        my $norm = $result->{$tt};
        # Identify a reference to that pair.

        # For each proposed expression that is a highest-scoring expression in the variety with
        # its degradation and whose score is sufficient for acceptance as an expression:
        if ($norm->{score} >= $mindeg && defined $norm->{tt}) {
        # If score of the pair is at least equal to the minimum score required for acceptance and
        # the pair has a text:

            if ($tt eq $norm->{tt}) {
            # If the pair’s text is identical to the text of the proposed expression:

                $exok{$tt} = '';
                # Add the proposed expression text to the table of texts to be accepted as
                # expressions.

            }

            elsif (!$strict || strict_match($tt, $norm->{tt})) {
            # Otherwise, if all definition texts with matching degradations are acceptable, or
            # if the pair’s text is identical to that of the proposed expression when parentheses
            # are removed from the pair’s text:

                $ttto{$tt} = $norm->{tt};
                # Add the pair’s text to the table of replacements for the proposed expression text.

            }
        }
    }

    foreach my $line (@lines) {
    # For each line of the input file:

        foreach my $tag (@{$line->[$excol]}) {
        # For each tagged item in the specified column:

            if (tags_match($tag, $extag)) {
            # If it is tagged as an expression:

                my $ex = $tag->[2];
                # Identify the item’s content, i.e. proposed text. 

                if (!exists $exok{$ex} && exists $ttto{$ex}) {
                # If it is not in the table of acceptable expression texts but has a replacement
                # in the table of replacements:

                    $tag = [ 
                        [ $exptag->[0], $exptag->[1], $tag->[2] ], 
                        [ $extag->[0], $extag->[1], $ttto{$ex} ]
                    ];
                    # Rewrite it as a pre-normalized expression and
                    # replacement expression.
                }
            }
        }

        $line->[$excol] = serialize_tags($line->[$excol]);
        # Identify the rewritten column.

        print $out join("\t", @$line), "\n";
        # Output the line.

    }

    if ($log) {
    # If logging is being performed:

        open my $log_fh, '>', "normalizedf${excol}.json" or die $!;
        # Open a logging file for writing.

        print $log_fh munge_json(JSON->new->pretty->canonical->encode($log_obj)), "\n";
        # Reformat the table of “norm” objects and output it to the file.

        close $log_fh if $log;
        # Close the file.

    }

}

sub strict_match {

    my ($old, $new) = @_;

    return $old eq $new =~ tr/()（）//dr;
    # Return whether the two specified strings are identical after all parentheses are removed
    # from the second one.

}

1;