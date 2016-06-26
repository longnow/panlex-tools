#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';

my %seen;

open my $out, '>', 'dcs_unmapped.txt' or die $!;

open my $in, '<', "$ENV{PANLEX_TOOLDIR}/serialize/data/csppmap.txt" or die $!;

while (<$in>) {
    chomp;
    my (undef, $cs) = split /\t/, $_, -1;
    $seen{$_} = 1 for split /‣/, $cs;
}

close $in;

open $in, '<', 'dcs.txt' or die $1;

while (<$in>) {
    chomp;

    my @cols = split /\t/, $_, -1;
    pop @cols;
    my $cs = join ':', @cols;

    print $out "$cs\n" unless $seen{$cs};
}

close $in;

close $out;