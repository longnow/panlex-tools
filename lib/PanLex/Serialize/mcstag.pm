# Tags meaning classifications.
# Arguments:
#   cols:   array of columns containing meaning classifications.

package PanLex::Serialize::mcstag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::cstag;

our @EXPORT = qw/mcstag/;

sub mcstag {
    my ($in, $out, $args) = @_;

    $args->{tag} //= 'mcs';

    cstag($in, $out, $args);
}

1;