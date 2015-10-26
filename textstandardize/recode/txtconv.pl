#!/usr/bin/env perl
use strict;
use warnings;
use Encode::TECkit;
binmode STDOUT, ':encoding(utf8)';

my ($fname) = @ARGV;

die "you must pass a .tec file as the first argument" unless -r $fname;

my $enc = Encode::TECkit->new($fname);

while (<STDIN>) {
    print $enc->decode($_);
}