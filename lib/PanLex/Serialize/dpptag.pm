# Tags denotation properties.
# Arguments:
#   cols:   array of columns containing denotation properties.
#   delim:  inter-property delimiter, '' if none. default ''.

package PanLex::Serialize::mpptag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::pptag;

our @EXPORT = qw/dpptag/;

sub dpptag {
    my ($in, $out, $args) = @_;

    $args = { %$args }; # don't pollute log.json
    $args->{tag} //= 'dpp';

    pptag($in, $out, $args);
}

1;