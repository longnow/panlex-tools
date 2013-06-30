# Converts a standard tagged source file to a full-text varilingual source file,
# eliminating duplicates.

# Arguments:
#    0: word classification to annotate all expressions as that have no tagged wc,
#        or blank if none.
#    1: minimum count (2 or more) of definitions and expressions per entry.
#    2: minimum count (1 or more) of expressions per entry.
#    3+: specifications (column index and variety UID, colon-delimited) of columns
#        containing tags (ex, df, dm) requiring variety specifications.

package PanLex::Serialize::out_full_0;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

our $final = 1;
# Declare that this script produces a final source file.

sub process {

    my ($in, $out, $wc, $mindf, $minex, @spec) = @_;

    die "invalid minimum count\n" if ($mindf < 2) || ($minex < 1);
    # If either minimum count is too small, quit and notify the user.

    print $out ":\n0\n";
    # Output the file header.

    my (%col, %en);

    foreach my $i (@spec) {
    # For each variety-specific column:

        my @col = split /:/, $i;
        # Identify its specification parts.

        validate_spec(@col);

        $col{$col[0]} = $col[1];
        # Add its index and variety UID to the table of variety-specific columns.

    }

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        for (my $i = 0; $i < @col; $i++) {
        # For each of them:

            if (exists $col{$i}) {
            # If it is variety-specific:

                $col[$i] =~ s/⫷ex⫸/⫷ex:$col{$i}⫸/g;
                # Insert the column's variety UID into each expression tag in it.

                $col[$i] =~ s/⫷df⫸/⫷df:$col{$i}⫸/g;
                # Insert the column's variety UID into each definition tag in it.

                $col[$i] =~ s/⫷dm⫸/⫷dm:$col{$i}⫸/g;
                # Insert the column's variety UID into each domain tag in it.

            }

        }

        my $en = join '', @col;
        # Identify a concatenation of its modified columns.

        $en =~ s/⫷exp⫸.+?(?=⫷ex:|⫷df|⫷dm|⫷mi|$)//g;
        # Delete all deprecated (i.e. pre-normalized) expressions in it.

        while ($en =~ s/(⫷df:[a-z]{3}-\d{3}⫸[^⫷]+)⫷(?:wc|md:[^⫸]+)⫸[^⫷]+/$1/) {}
        # Delete all word classifications or metadata following definitions.

        while ($en =~ s/((⫷(?:wc|md:[^⫸]+)⫸[^⫷⫸]+)(?:⫷(?:wc|md:[^⫸]+)⫸[^⫷⫸]+)*)\2(?=⫷|$)/$1/) {}
        # Delete all duplicate wc and md elements of any ex element in it.

        while ($en =~ s/((⫷((?:df|dm):[^⫸]+)⫸[^⫷⫸]+)(?:⫷.+?)?)\2(?=⫷|$)/$1/) {}
        # Delete all duplicate df and dm elements in it.

        while ($en =~ s/((⫷ex:[^⫸]+⫸[^⫷⫸]+)(?:⫷.+?)?)\K\2(?:⫷(?:wc|md:[^⫸]+)⫸[^⫷⫸]+)*(?=⫷|$)//) {}
        # Delete all duplicate ex elements in it.

        next if (
            (() = $en =~ /(⫷(?:ex|df):)/g) < $mindf
            || (() = $en =~ /(⫷ex:)/g) < $minex
        );
        # If the count of remaining expressions and definitions or the count of remaining
        # expressions is smaller than the minimum, disregard the line.

        $en =~ s/⫷mi⫸/\nmi\n/g;
        # Convert all meaning-identifier tags in it.

        $en =~ s/⫷(ex|df|dm):([a-z]{3}-\d{3})⫸/\n$1\n$2\n/g;
        # Convert all expression, definition, and domain tags in it.

        $en =~ s/⫷wc⫸/\nwc\n/g;
        # Convert all word-classification tags in it.

        $en =~ s/⫷md:(.+?)⫸/\nmd\n$1\n/g;
        # Convert all metadatum tags in it.

        unless (exists $en{$en}) {
        # If the converted line is not a duplicate:

            $en{$en} = '';
            # Add it to the table of lines.

            print $out $en, "\n";
            # Output it.

        }

    }

}

1;