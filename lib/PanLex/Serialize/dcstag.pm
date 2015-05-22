# Tags denotation classifications.
# Arguments:
#   cols:   array of columns containing denotation classifications.

package PanLex::Serialize::dcstag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::cstag;

our @EXPORT = qw/dcstag/;

sub dcstag {
    my ($in, $out, $args) = @_;

    $args->{tag} //= 'dcs';

    cstag($in, $out, $args);
}

1;