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
#               default 0.
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
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($excol, $uid, $mindeg, $ui, $strict, $log, $ignore, $extag, $exptag);
    
    if (ref $args eq 'HASH') {
        $excol      = $args->{col};
        $uid        = $args->{uid};
        $mindeg     = $args->{mindeg};
        $ui         = $args->{ui} // $args->{ap} // [];
        $strict     = $args->{strict} // 1;
        $log        = $args->{log} // 0;
        $ignore     = $args->{ignore} // '';
        $extag      = $args->{extag} // '⫷ex⫸';
        $exptag     = $args->{exptag} // '⫷exp⫸';
    } else {
        die "invalid arguments: you must pass a hashref";
    }

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
        # Identify the tagged items in it.

        foreach my $tag (@{$line->[$excol]}) {
        # For each of the tagged items:

            if (tags_match($tag, $extag)) {
            # If it is tagged as an expression:

                my $ex = $tag->[2];
                # Identify the expression.

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

    my %ttto;

    my $result = panlex_norm('df', $uid, [keys %ex], 1, $ui);

    $log_obj = $result if $log;

    foreach my $tt (keys %$result) {
        # Identify the highest-scoring expression.
        my $norm = $result->{$tt}[0];

        # For each proposed expression that is a highest-scoring expression in the variety with
        # its degradation and whose score is sufficient for acceptance as an expression:
        if ($norm->{score} >= $mindeg && defined $norm->{tt}) {
            if ($tt eq $norm->{tt}) {
                $exok{$tt} = '';
            } elsif (!$strict || strict_match($tt, $norm->{tt})) {
                $ttto{$tt} = $norm->{tt};
            }
        }
    }

    foreach my $line (@lines) {
    # For each line:

        foreach my $tag (@{$line->[$excol]}) {
        # For each item:

            if (tags_match($tag, $extag)) {
            # If it is tagged as an expression:

                my $ex = $tag->[2];
                # Identify the string. 

                if (!exists $exok{$ex} && exists $ttto{$ex}) {
                # If it is not classifiable as an expression without
                # replacement and has a replacement:

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
        open my $log_fh, '>', "normalizedf${excol}.json" or die $!;
        print $log_fh munge_json(JSON->new->pretty->canonical->encode($log_obj)), "\n";
        close $log_fh if $log;
    }
}

sub strict_match {
    my ($old, $new) = @_;

    return $old eq $new =~ tr/()//dr;
}

1;