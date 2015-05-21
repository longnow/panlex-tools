package PanLex::Normalize::ron000;
use strict;
use parent 'PanLex::Normalize';

sub ex {
    my ($self, $str) = @_;
    return $self->convert_chars($str, "\x{327}", "\x{326}");
}

1;