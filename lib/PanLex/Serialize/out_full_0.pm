# Converts a standard tagged source file to a full-text varilingual source file.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing tags (e.g., ex, df, dm) requiring variety
#             specifications.
#   mindf:  minimum count (1 or more) of definitions and expressions per entry.
#             default 2.
#   minex:  minimum count (0 or more) of expressions per entry. default 1.

package PanLex::Serialize::out_full_0;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::Util;

our @EXPORT = qw/out_full_0/;

my $UID = qr/[a-z]{3}-\d{3}/;

sub out_full_0 {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@specs, $mindf, $minex);
    
    if (ref $args eq 'HASH') {
        validate_specs($args->{specs});

        @specs  = @{$args->{specs}};
        $mindf  = $args->{mindf} // 2;
        $minex  = $args->{minex} // 1;
    } else {
        (undef, $mindf, $minex, @specs) = @$args;
        validate_specs(\@specs);
    }
        
    die "invalid minimum count\n" if ($mindf < 1) || ($minex < 0);
    # If either minimum count is too small, quit and notify the user.

    print $out ":\n0\n";
    # Output the file header.

    my $col_uid = parse_specs(\@specs);

    my %seen;

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

                $col[$i] =~ s/⫷(ex|df|dm)⫸/⫷$1:$col_uid->{$i}⫸/g;
                # Insert the column's variety UID into each tag in it.

            }

        }

        my $rec = join '', @col;
        # Identify a concatenation of its modified columns.

        s/⫷(?:exp|rm)⫸[^⫷]*//g;
        # Delete all pre-normalized expressions and all tags that are marked as to be removed.

        while ($rec =~ s/(⫷df:$UID⫸[^⫷]+)⫷(?:wc|md:[^⫸]+)⫸[^⫷]+/$1/) {}
        # Delete all word classifications or metadata following definitions.

        while ($rec =~ s/((⫷(?:wc|md:[^⫸]+)⫸[^⫷]+)(?:⫷(?:wc|md:[^⫸]+)⫸[^⫷]+)*)\2(?=⫷|$)/$1/) {}
        # Delete all duplicate wc and md elements of any ex element in it.

        while ($rec =~ s/((⫷((?:df|dm):$UID)⫸[^⫷]+)(?:⫷.+?)?)\2(?=⫷|$)/$1/) {}
        # Delete all duplicate df and dm elements in it.

        while ($rec =~ s/((⫷ex:$UID+⫸[^⫷]+)(?:⫷.+?)?)\K\2(?:⫷(?:wc|md:[^⫸]+)⫸[^⫷]+)*(?=⫷|$)//) {}
        # Delete all duplicate ex elements in it.

        next if (
            (() = $rec =~ /(⫷(?:ex|df):)/g) < $mindf
            || (() = $rec =~ /(⫷ex:)/g) < $minex
        );
        # If the count of remaining expressions and definitions or the count of remaining
        # expressions is smaller than the minimum, disregard the line.

        unless (exists $seen{$rec}) {
        # If the converted line is not a duplicate:

            $seen{$rec} = '';
            # Add it to the table of lines.

            $rec =~ s/⫷mi⫸/\nmi\n/g;
            # Convert all meaning-identifier tags in it.

            $rec =~ s/⫷(ex|df|dm):([a-z]{3}-\d{3})⫸/\n$1\n$2\n/g;
            # Convert all expression, definition, and domain tags in it.

            $rec =~ s/⫷wc⫸/\nwc\n/g;
            # Convert all word-classification tags in it.

            $rec =~ s/⫷md:([^⫸]+)⫸/\nmd\n$1\n/g;
            # Convert all metadatum tags in it.

            print $out $rec, "\n";
            # Output it.

        }

    }

}

1;
