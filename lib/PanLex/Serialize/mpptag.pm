# Tags meaning properties.
# Arguments:
#   cols:   array of columns containing meaning properties.

package PanLex::Serialize::mpptag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::pptag;

our @EXPORT = qw/mpptag/;

sub mpptag {
    my ($in, $out, $args) = @_;

    $args->{tag} //= 'mpp';

    pptag($in, $out, $args);
}

1;