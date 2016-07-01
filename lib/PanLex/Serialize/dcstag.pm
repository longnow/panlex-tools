# Tags denotation classifications.
# Arguments:
#   cols:   array of columns containing denotation classifications.
#   delim:  inter-classification delimiter, or '' if none. default '‣'.
#   prefix: string to prefix to each classification before parsing, or '' if none.
#             default ''.

package PanLex::Serialize::dcstag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::cstag;

our @EXPORT = qw(dcstag);

sub dcstag {
    my ($in, $out, $args) = @_;

    $args = { %$args }; # don't pollute log.json
    $args->{tag} //= 'dcs';

    cstag($in, $out, $args);
}

1;