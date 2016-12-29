#!/usr/bin/env perl
use strict;
use warnings;
use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Client;
binmode STDOUT, ':encoding(utf8)';

my @ISO_UID = qw( art-001 art-002 art-003 art-005 art-015 );
my $GLOTTO_UID = 'art-327';

die "you must provide a filename (one language name per line)" unless @ARGV;

my ($filename) = @ARGV;
die "could not read file: $filename" unless -r $filename;

my (@langnames, %langname_td, %td);

open my $fh, '<:crlf:encoding(utf-8)', $filename or die $!;

@langnames = <$fh>;
chomp @langnames;

close $fh;

my $data = panlex_query('/td', { tt => \@langnames });

foreach my $langname (keys %{$data->{td}}) {
    $langname_td{$langname} = $data->{td}{$langname};
}

$data = panlex_query_all('/lv', {});

foreach my $lv (@{$data->{result}}) {
    push @{$td{uid}{$lv->{td}}}, $lv->{uid};
}

$data = panlex_query_all('/ex', {
    uid => [ @ISO_UID, $GLOTTO_UID ],
    trtd => \@langnames,
    include => ['trtd','uid'],
});

foreach my $ex (@{$data->{result}}) {
    my $type = $ex->{uid} eq $GLOTTO_UID ? 'glotto' : 'iso';
    push @{$td{$type}{$ex->{trtd}}}, $ex->{tt};
}

print join("\t", 'Name', 'PanLex UIDs', 'ISO 639 codes', 'Glottocodes'), "\n";

foreach my $langname (@langnames) {
    my $td = $langname_td{$langname};

    print join("\t",
        $langname,
        join('; ', sort { $a cmp $b } uniq(@{$td{uid}{$td} || []})),
        join('; ', sort { $a cmp $b } uniq(@{$td{iso}{$td} || []})),
        join('; ', sort { $a cmp $b } uniq(@{$td{glotto}{$td} || []})),
    ), "\n";
}

sub uniq {
    my %seen;
    @seen{@_} = ();
    return keys %seen;
}
