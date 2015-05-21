# Tags meaning identifiers.
# Arguments:
#   col:    column that contains meaning identifiers.
#   mitag:  meaning-identifier tag. default '⫷mi⫸'.

package PanLex::Serialize::mitag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';

our @EXPORT = qw/mitag/;

use PanLex::Validation;

sub mitag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($micol, $mitag);
    
    if (ref $args eq 'HASH') {
        $micol    = $args->{col};
        $mitag    = $args->{mitag} // '⫷mi⫸';      
    } else {
        ($micol, $mitag) = @$args;
    }

    validate_col($micol);    
    
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