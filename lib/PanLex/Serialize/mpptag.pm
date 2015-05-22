# Tags meaning properties.
# Arguments:
#   cols:   array of columns containing meaning properties.
#   delim:  inter-classification delimiter, or '' if none. default ''.

package PanLex::Serialize::mpptag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::pptag;

our @EXPORT = qw/mpptag/;

sub mpptag {
    my ($in, $out, $args) = @_;

    $args = { %$args }; # don't pollute log.json
    $args->{tag} //= 'mpp';

    pptag($in, $out, $args);
}

1;