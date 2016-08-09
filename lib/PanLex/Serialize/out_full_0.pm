# Converts a standard tagged source file to a full-text varilingual source file.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing tags (e.g., ex, df, mcs, dcs) requiring variety
#             specifications.
#   mindf:  minimum count (0 or more) of definitions and expressions per entry.
#             default 2.
#   minex:  minimum count (0 or more) of expressions per entry. default 1.
#   remove_tags: regular expression matching tag types to be removed prior to
#             serialization, or '' if none. default '^(?:exp|rm)$'.
#   error:  indicates what to do when certain common errors are detected. use
#             'mark' to mark errors in the output file, 'fail' to immediately
#             abort, and 'ignore' to do nothing. default 'mark'.

package PanLex::Serialize::out_full_0;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::Util;
use PanLex::Client;
use panlex_ucd;
use JSON::MaybeXS;

our @EXPORT = qw(out_full_0);

my $UID = qr/[a-z]{3}-\d{3}/; # matches a language variety UID

sub out_full_0 {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@specs, $mindf, $minex, $error, $remove_tags);

    if (ref $args eq 'HASH') {
        validate_specs($args->{specs});

        @specs = @{$args->{specs}};
        $mindf = $args->{mindf} // 2;
        $minex = $args->{minex} // 1;
        $error = $args->{error} // 'mark';
        $remove_tags = $args->{remove_tags} // '^(?:exp|rm)$';
    } else {
        (undef, $mindf, $minex, @specs) = @$args;
        validate_specs(\@specs);
        $error = 'ignore';
        $remove_tags = '^(?:exp|rm)$';
    }

    die "invalid minimum count\n" if ($mindf < 0) || ($minex < 0);
    # If either minimum count is too small, quit and notify the user.

    die "invalid value for error parameter: $error" if $error !~ /^(mark|fail|ignore)$/;

    print $out ":\n0\n";
    # Output the file header.

    my $col_uid = parse_specs(\@specs);

    my %seen_rec;

    my $error_count = 0;

    my $report_error = sub {
        my ($errstr, $line) = @_;
        die "$errstr\n$line\n" if $error eq 'fail';
        $error_count++;
        return "ERROR: $errstr\n$line";
    };

    my %uid_immutable;

    if ($error ne 'ignore') {
        my $data = panlex_query_all('/lv', { mu => JSON->false, cache => 0 });

        foreach my $lv (@{$data->{result} || []}) {
            $uid_immutable{$lv->{uid}} = undef;
        }
    }

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (keys %$col_uid) {
        # For each of them that is variety-specific:

            $col[$i] =~ s/⫷(ex|df|[dm]cs)⫸/⫷$1:$col_uid->{$i}⫸/g;
            # Insert the column's variety UID into each tag in it.

        }

        my $tags = parse_tags(join('', @col));
        # Identify a list of tags from its modified columns.

        if ($remove_tags ne '') {
            $tags = [ grep { $_->[0] !~ /$remove_tags/ } @$tags ];
            # Delete all tags that are to be removed.
        }

        foreach my $tag (@$tags) {
            $tag->[0] = 'dn' if $tag->[0] eq 'ex';
        }
        # Convert all ex tags to dn.

        $tags = combine_complex_tags($tags);
        # Combine classification and property tags into subarrays.

        my %seen;

        for (my $i = 0; $i < @$tags; $i++) {
            my $type = tag_type($tags->[$i]);

            next unless $type =~ /^(?:dn|df|[dm]cs[12]|[dm]pp)$/;

            if ($type eq 'df') {
                for (my $j = $i+1; $j < @$tags && tag_type($tags->[$j]) =~ /^dcs[12]|dpp$/; ) {
                    splice @$tags, $j, 1;
                }
            }
            # Delete all denotation items following definitions.

            my $str = serialize_tags([ $tags->[$i] ]);

            if (exists $seen{$type}{$str}) {
                if ($type eq 'dn') {
                    for (my $j = $i+1; $j < @$tags && tag_type($tags->[$j]) =~ /^dcs[12]|dpp$/; ) {
                        splice @$tags, $j, 1;
                    }
                }
                # Delete all denotation items following duplicate denotations.

                splice @$tags, $i--, 1;
                # Delete all duplicate dn, df, dcs, dpp, mcs, and mpp tags.
            } else {
                $seen{$type}{$str} = '';

                if ($type eq 'dn') {
                    $seen{$_} = {} for (qw( dcs1 dcs2 dpp ));
                    # Reset the duplicate tables for denotation items.
                }
            }
        }

        next if
            scalar(grep { tag_type($_) =~ /^(?:dn|df)$/ } @$tags) < $mindf ||
            scalar(grep { tag_type($_) eq 'dn' } @$tags) < $minex;
        # If the count of remaining expressions and definitions or the count of remaining
        # expressions is smaller than the minimum, disregard the line.

        my $rec = serialize_tags($tags);

        next if exists $seen_rec{$rec};
        # Skip the record if it is a duplicate.

        $seen_rec{$rec} = '';
        # Add it to the table of lines.

        $rec =~ s/⫷(dn|df):($UID)⫸/\n  $1\n    $2\n    /g;
        # Convert all expression and definition tags in it.

        $rec =~ s/⫷(mcs[12]|mpp):($UID)⫸/\n  $1\n    $2\n    /g;
        # Convert all initial meaning classification and property tags in it.

        $rec =~ s/⫷(?:mcs):($UID)⫸/\n    $1\n    /g;
        # Convert all remaining meaning classification tags in it.

        $rec =~ s/⫷(?:mpp)⫸/\n    /g;
        # Convert all remaining meaning property tags in it.

        $rec =~ s/⫷(dcs[12]|dpp):($UID)⫸/\n    $1\n      $2\n      /g;
        # Convert all initial denotation classification and property tags in it.

        $rec =~ s/⫷(?:dcs):($UID)⫸/\n      $1\n      /g;
        # Convert all remaining denotation classification tags in it.

        $rec =~ s/⫷(?:dpp)⫸/\n      /g;
        # Convert all remaining denotation property tags in it.

        $rec =~ s/^\n+//g;
        # Remove any initial newlines.

        if ($error ne 'ignore') {
            my @lines = split /\n/, $rec, -1;

            my $error_count_orig = $error_count;
            my $check_cspp_ex = 0;

            foreach my $line (@lines) {
                my $line_stripped = $line =~ s/^ +//r;

                if ($line_stripped eq '') {
                    $line = $report_error->('empty line', $line);
                } else {
                    if ($line =~ /(\p{IsProhibited})/) {
                        my $code = sprintf "%X", ord($1);
                        $line = $report_error->("line contains prohibited character U+$code", $line);
                    }

                    $line = $report_error->('not an immutable language variety', $line)
                        if $check_cspp_ex && $line_stripped =~ $UID && !exists $uid_immutable{$line_stripped};

                    $line = $report_error->('line contains ⫷ or ⫸', $line)
                        if $line =~ /[⫷⫸]/;

                    $line = $report_error->('line contains ASCII apostrophe', $line)
                        if $line =~ /'/;

                    $line = $report_error->('line contains improperly corrected ellipsis', $line)
                        if $line =~ /\.{2,}|…\.|\.…/;

                    my $count = 0;
                    while ($line =~ / \( (?{ $count++ }) | \) (?{ $count-- }) /gx) {
                        last if $count < 0;
                    }
                    $line = $report_error->('line contains unbalanced parentheses', $line)
                        if $count != 0;

                    $count = 0;
                    while ($line =~ / \[ (?{ $count++ }) | \] (?{ $count-- }) /gx) {
                        last if $count < 0;
                    }
                    $line = $report_error->('line contains unbalanced brackets', $line)
                        if $count != 0;
                }

                $check_cspp_ex = $line_stripped =~ /^[dm](?:cs2|pp)$/ ? 1 : 0;
            }

            $rec = join("\n", @lines) if $error_count > $error_count_orig;
        }

        print $out "\nmn\n$rec\n";
        # Output it.

    }

    print "\n$error_count errors detected; check final file for ERROR lines\n" if $error_count;

}

1;
