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
use PanLex::Validation;
use PanLex::Serialize::Util;

our @EXPORT = qw/out_simple_0/;

my $UID = qr/[a-z]{3}-\d{3}/;

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

            if (exists $col_uid{$i}) {
                # If it is an expression column:

                $col[$i] =~ s/⫷ex⫸/⫷ex:$col_uid{$i}⫸/g;
                # Insert the column's variety UID into each expression tag in it.
            }
        }

        my $rec = join '', @col;
        # Identify a concatenation of its modified columns.

        $rec =~ s/⫷(?:exp|rm)⫸[^⫷]*//g;
        # Delete all pre-normalized expressions and all tags that are marked as to be removed.

        unless (exists $seen{$rec}) {
        # If it is not a duplicate:

            $seen{$rec} = '';
            # Add it to the table of entries.

            $rec =~ s/⫷ex:($UID)⫸/\n$1\n/g;
            # Convert all expression tags in it.

            print $out $rec, "\n";
            # Output the converted line.
        }
    }
};

1;