# Tags meaning identifiers.
# Arguments:
#    0: column that contains meaning identifiers.
#    1: meaning-identifier tag.

package PanLex::Serialize::mitag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub process {
    my ($in, $out, $micol, $mitag) = @_;
    
    validate_col($micol);

    while (<$in>) {
    # For each line of the input file:

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $micol not present in line: $_" unless defined $col[$micol];

        $col[$micol] = "$mitag$col[$micol]" if length $col[$micol];
        # Prefix a meaning-identifier tag to the meaning-identifier column's content,
        # if not blank.

        print $out join("\t", @col);
        # Output the line.
    }    
}

1;