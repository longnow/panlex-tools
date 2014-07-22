#!/usr/bin/env perl
use strict;
binmode STDIN, ':encoding(utf8)';

my $char;

while (read STDIN, $char, 1) {
    print pack('C', ord($char));    
}