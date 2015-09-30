# Converts a standard tagged source file to a full-text varilingual source file.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing tags (e.g., ex, df, mcs, dcs) requiring variety
#             specifications.
#   mindf:  minimum count (0 or more) of definitions and expressions per entry.
#             default 2.
#   minex:  minimum count (0 or more) of expressions per entry. default 1.
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

our @EXPORT = qw/out_full_0/;

my $UID = qr/[a-z]{3}-\d{3}/; # matches a language variety UID
my $DF = qr/⫷df:$UID⫸[^⫷]+/; # matches definitions
my $DCSDPP = qr/⫷dcs1:$UID⫸[^⫷]+|⫷dcs2:$UID⫸[^⫷]+⫷dcs:$UID⫸[^⫷]+|⫷dpp:$UID⫸[^⫷]+⫷dpp⫸[^⫷]+/; # matches denotation classifications or properties
my $MCSMPP = qr/⫷mcs1:$UID⫸[^⫷]+|⫷mcs2:$UID⫸[^⫷]+⫷mcs:$UID⫸[^⫷]+|⫷mpp:$UID⫸[^⫷]+⫷mpp⫸[^⫷]+/; # matches meaning classifications or properties

sub out_full_0 {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@specs, $mindf, $minex, $error);
    
    if (ref $args eq 'HASH') {
        validate_specs($args->{specs});

        @specs = @{$args->{specs}};
        $mindf = $args->{mindf} // 2;
        $minex = $args->{minex} // 1;
        $error = $args->{error} // 'mark';
    } else {
        (undef, $mindf, $minex, @specs) = @$args;
        $error = 'ignore';
        validate_specs(\@specs);
    }
        
    die "invalid minimum count\n" if ($mindf < 0) || ($minex < 0);
    # If either minimum count is too small, quit and notify the user.

    die "invalid value for error parameter: $error" if $error !~ /^(mark|fail|ignore)$/;

    print $out ":\n0";
    # Output the file header.

    my $col_uid = parse_specs(\@specs);

    my %seen;

    my $error_count = 0;

    my $report_error = sub {
        my ($errstr, $line) = @_;
        die $errstr if $error eq 'fail';
        $error_count++;        
        return "ERROR: $errstr\n$line";
    };

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        for (my $i = 0; $i < @col; $i++) {
        # For each of them:

            if (exists $col_uid->{$i}) {
            # If it is variety-specific:

                $col[$i] =~ s/⫷(ex|df|[dm]cs)⫸/⫷$1:$col_uid->{$i}⫸/g;
                # Insert the column's variety UID into each tag in it.

            }

        }

        my $rec = join '', @col;
        # Identify a concatenation of its modified columns.

        $rec =~ s/⫷(?:exp|rm)⫸[^⫷]*//g;
        # Delete all pre-normalized expressions and all tags that are marked as to be removed.

        $rec =~ s/⫷ex(?=:)/⫷dn/g;
        # Convert all ex tags to dn.

        while ($rec =~ s/($DF)(?:$DCSDPP)/$1/) {}
        # Delete all denotation classifications and properties following definitions.

        while ($rec =~ s/(($DCSDPP)(?:$DCSDPP)*)\2(?=⫷|$)/$1/) {}
        # Delete all duplicate denotation classifications and properties of any dn element in it.

        while ($rec =~ s/(($DF|$MCSMPP)(?:⫷.+?)?)\2(?=⫷|$)/$1/) {}
        # Delete all duplicate df elements and meaning classifications and properties in it.

        while ($rec =~ s/((⫷dn:$UID+⫸[^⫷]+)(?:⫷.+?)?)\K\2(?:$DCSDPP)*(?=⫷|$)//) {}
        # Delete all duplicate dn elements in it.

        next if (
            (() = $rec =~ /(⫷(?:dn|df):)/g) < $mindf
            || (() = $rec =~ /(⫷dn:)/g) < $minex
        );
        # If the count of remaining expressions and definitions or the count of remaining
        # expressions is smaller than the minimum, disregard the line.

        unless (exists $seen{$rec}) {
        # If the converted line is not a duplicate:

            $seen{$rec} = '';
            # Add it to the table of lines.

            $rec =~ s/⫷(dn|df|[dm]cs[12]|[dm]pp):($UID)⫸/\n$1\n$2\n/g;
            # Convert all expression, definition, and initial classification and property 
            # tags in it.

            $rec =~ s/⫷(?:[dm]cs):($UID)⫸/\n$1\n/g;
            # Convert all remaining classification tags in it.

            $rec =~ s/⫷(?:[dm]pp)⫸/\n/g;
            # Convert all remaining property tags in it.

            if ($error ne 'ignore') {
                my @lines = split /\n/, $rec, -1;
                shift @lines; # remove initial empty line
                my $error_count_orig = $error_count;

                foreach my $line (@lines) {
                    $line = $report_error->('empty line', $line), next
                        if $line eq '';

                    $line = $report_error->('line contains ⫷ or ⫸', $line)
                        if $line =~ /[⫷⫸]/;

                    $line = $report_error->('line contains ASCII apostrophe', $line)
                        if $line =~ /'/;

                    $line = $report_error->('line contains improperly corrected ellipsis', $line)
                        if $line =~ /\.{2,}|…\.|\.…/;
                }

                $rec = "\n" . join("\n", @lines) if $error_count > $error_count_orig;
            }

            print $out "\nmn$rec\n";
            # Output it.

        }

    }

    print "\n$error_count errors detected; check final file for ERROR lines\n" if $error_count;

}

1;
