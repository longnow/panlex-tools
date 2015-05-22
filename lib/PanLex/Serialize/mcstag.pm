# Tags meaning classifications.
# Arguments:
#   cols:   array of columns containing meaning classifications.
#   delim:  inter-classification delimiter, or '' if none. default ''.

package PanLex::Serialize::mcstag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::cstag;

our @EXPORT = qw/mcstag/;

sub mcstag {
    my ($in, $out, $args) = @_;

    $args = { %$args }; # don't pollute log.json
    $args->{tag} //= 'mcs';

    cstag($in, $out, $args);
}

1;