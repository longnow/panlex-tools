# Converts a normally tagged source file to a simple-text varilingual source file,
# eliminating duplicates.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing expressions.

package PanLex::Serialize::out_simple_0;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';

use vars qw/@EXPORT/;
@EXPORT = qw/out_simple_0/;

use PanLex::Validation;

sub out_simple_0 {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my @specs;
    
    if (ref $args eq 'HASH') {
        validate_specs($args->{specs});
        @specs = @{$args->{specs}};
    } else {
        @specs = @$args;
        validate_specs(\@specs);
    }
    
    print $out ".\n0\n";
    # Output the file header.

    my (%all, %col);

    foreach my $i (@specs) {
    # For each expression column:

        my @col = split /:/, $i;
        # Identify its specification parts.

        $col{$col[0]} = $col[1];
        # Add its index and variety UID to the table of expression columns.
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
                # If it is an expression column:

                $col[$i] =~ s/⫷ex⫸/⫷ex:$col{$i}⫸/g;
                # Insert the column's variety UID into each expression tag in it.
            }
        }

        my $en = join '', @col;
        # Identify a concatenation of its modified columns.

        $en =~ s/⫷exp⫸.+?(?=⫷ex:)//g;
        # Delete all deprecated (i.e. pre-normalized) expressions in it.

        $en =~ s/⫷rm⫸[^⫷]+//g;
        # Delete all tags that are marked as to be removed.

        unless (exists $all{$en}) {
        # If it is not a duplicate:

            $all{$en} = '';
            # Add it to the table of entries.

            $en =~ s/⫷ex:([a-z]{3}-\d{3})⫸/\n$1\n/g;
            # Convert all expression tags in it.

            print $out $en, "\n";
            # Output the converted line.
        }
    }
};

1;