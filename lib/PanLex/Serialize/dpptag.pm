# Tags denotation properties.
# Arguments:
#   cols:   array of columns containing denotation properties.
#   delim:  inter-property delimiter, or '' if none. default '‣'.
#   prefix: string to prefix to each property before parsing, or '' if none.
#             default ''.

package PanLex::Serialize::dpptag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::pptag;

our @EXPORT = qw(dpptag);

sub dpptag {
    my ($in, $out, $args) = @_;

    $args = { %$args }; # don't pollute log.json
    $args->{tag} //= 'dpp';

    pptag($in, $out, $args);
}

1;