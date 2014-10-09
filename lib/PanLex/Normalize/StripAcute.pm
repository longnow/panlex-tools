package PanLex::Normalize::StripAcute;
use strict;
use base 'PanLex::Normalize';

sub norm {
    my ($self, $str) = @_;
    return $self->strip_specified_accents($str, "\x{301}");
}

1;