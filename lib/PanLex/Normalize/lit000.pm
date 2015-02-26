package PanLex::Normalize::lit000;
use strict;
use base 'PanLex::Normalize';

sub ex {
    my ($self, $str) = @_;
    return $self->strip_specified_accents($str, "\x{300}\x{301}\x{303}");
}

1;
