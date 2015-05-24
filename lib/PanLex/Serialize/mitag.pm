# Tags meaning identifiers.
# Arguments:
#   col:    column that contains meaning identifiers.

package PanLex::Serialize::mitag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::mpptag;

our @EXPORT = qw/mitag/;

sub mitag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($micol);
    
    if (ref $args eq 'HASH') {
        $micol    = $args->{col};
    } else {
        ($micol) = @$args;
    }

    validate_col($micol);    

    mpptag($in, $out, { cols => [$micol], prefix => 'art-301⁋identifier⁋' });
}

1;