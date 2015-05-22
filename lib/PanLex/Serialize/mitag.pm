# Tags meaning identifiers.
# Arguments:
#   col:    column that contains meaning identifiers.

package PanLex::Serialize::mitag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::replace;
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

    my $temp;

    open my $fh, '>:encoding(utf8)', \$temp or die $!;
    replace($in, $fh, { cols => [$micol], from => '^', to => 'art-301⁋identifier⁋' });
    close $fh;

    open $fh, '<:encoding(utf8)', \$temp or die $!;
    mpptag($fh, $out, { cols => [$micol] });
    close $fh;
}

1;