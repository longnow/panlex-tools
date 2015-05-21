package PanLex::Normalize::StripAcute;
use strict;
use parent 'PanLex::Normalize';

sub ex {
    my ($self, $str) = @_;
    return $self->strip_specified_accents($str, "\x{301}");
}

1;