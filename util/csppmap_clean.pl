#!/usr/bin/env perl
use strict;
use warnings;
use lib "$ENV{PANLEX_TOOLDIR}/lib";
use File::Spec::Functions;
use PanLex::Client;
binmode STDOUT, ':encoding(utf-8)';

my %map;

my $file = $ARGV[0] // 'csppmap.txt';
$file = catfile($ENV{PANLEX_TOOLDIR}, 'serialize', 'data', $file) unless -e $file;

open my $mapin, '<:encoding(utf-8)', $file or die $!;

while (<$mapin>) {
    chomp;

    my @col = split /\t/, $_, 2;

    $col[0] =~ s/\. +(?=.+\.)/\./g;
    $col[0] = lc $col[0] if $col[0] =~ /\./ || $col[0] =~ /^[A-Z][a-zA-Z]*$/;

    $map{$col[0]} = $col[1];
}

close $mapin;

my $key_td = panlex_query_map('/td', { tt => [keys %map] }, 'tt', 'td');

my %td_map;

foreach my $key (keys %map) {
    push @{$td_map{$key_td->{$key}}}, $key;
}

foreach my $key (sort keys %td_map) {
    my $mapped = $td_map{$key};
    next if @$mapped < 2;

    if (@$mapped == 2) {
        @$mapped = sort @$mapped;
        if ($mapped->[0].'.' eq $mapped->[1]) {
            delete $map{$mapped->[0]};
            next;
        }
    }

    print "$key is degradation of multiple items: ", join('; ', sort @$mapped), "\n";

    my $first_key = shift @$mapped;

    foreach my $other_key (@$mapped) {
        if ($map{$first_key} ne $map{$other_key}) {
            print "... and those items' mapping values also do not match\n";
            last;
        }
    }
}

open my $mapout, '>:encoding(utf-8)', $file or die $!;

foreach my $key (sort { lc $a eq lc $b ? $a cmp $b : lc $a cmp lc $b } keys %map) {
    print $mapout join("\t", $key, $map{$key} // ()), "\n";
}

close $mapout;
