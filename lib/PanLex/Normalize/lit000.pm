package PanLex::Normalize::lit000;
use strict;
use parent 'PanLex::Normalize';

sub text {
    my ($self, $str) = @_;
    return $self->strip_specified_accents($str, "\x{300}\x{301}\x{303}");
}

1;
