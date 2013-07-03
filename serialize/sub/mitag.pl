# Tags meaning identifiers.
# Arguments:
#   col:    column that contains meaning identifiers.
#   mitag:  meaning-identifier tag. default '⫷mi⫸'.

package PanLex::Serialize::mitag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub process {
    my ($in, $out, $args) = @_;
    
    validate_col($args->{col});
    
    my $micol   = $args->{col};
    my $mitag   = defined $args->{mitag} ? $args->{mitag} : '⫷mi⫸';
    
    while (<$in>) {
    # For each line of the input file:

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $micol not present in line" unless defined $col[$micol];

        $col[$micol] = "$mitag$col[$micol]" if length $col[$micol];
        # Prefix a meaning-identifier tag to the meaning-identifier column's content,
        # if not blank.

        print $out join("\t", @col);
        # Output the line.
    }    
}

1;