#!/usr/bin/env perl
use strict;
use warnings;
use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Client;
use Data::Dumper;
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my @ISO_UID = qw( art-001 art-002 art-003 art-005 art-015 );
my $GLOTTO_UID = 'art-327';
my $PANLEX_UID = 'art-274';

my (@langnames, %langname_txt_degr, %txt_degr);

print STDERR "\n";

if (@ARGV and $ARGV[0] ne '-') {
    my ($filename) = @ARGV;
    die "cannot read $filename" unless -r $filename;

    print STDERR "reading language names from $filename (one name per line) ...\n";
    open my $fh, '<:crlf:encoding(utf-8)', $filename or die $!;
    @langnames = <$fh>;
    close $fh;

}
else {
    print STDERR "reading language names from stdin (one name per line) ...\n";
    @langnames = <STDIN>;
}

chomp @langnames;

@langnames = grep { length $_ } @langnames;

print STDERR "generating text degradations of languge names ...\n";
my $data = panlex_query('/txt_degr', { txt => \@langnames });

foreach my $langname (keys %{$data->{txt_degr}}) {
    $langname_txt_degr{$langname} = $data->{txt_degr}{$langname};
}

print STDERR "looking up all PanLex language variety names ...\n";
$data = panlex_query_all('/expr', {
    trans_uid   => $PANLEX_UID,
    include     => 'trans_txt',
    cache       => 0,
});

foreach my $expr (@{$data->{result}}) {
    $txt_degr{uid}{$expr->{txt_degr}}{$expr->{trans_txt}} = undef;
}

print STDERR "looking up ISO 639 codes and Glottocodes corresponding to language names ...\n";
$data = panlex_query_all('/expr', {
    uid             => [ @ISO_UID, $GLOTTO_UID ],
    trans_txt_degr  => \@langnames,
    include         => ['trans_txt_degr','uid'],
    cache           => 0,
});

foreach my $expr (@{$data->{result}}) {
    my $type = $expr->{uid} eq $GLOTTO_UID ? 'glotto' : 'iso';
    $txt_degr{$type}{$expr->{trans_txt_degr}}{$expr->{txt}} = undef;
}

print STDERR "done.\n\n";

print join("\t", 'Name', 'PanLex UIDs', 'ISO 639 codes', 'Glottocodes'), "\n";

foreach my $langname (@langnames) {
    my $txt_degr = $langname_txt_degr{$langname};

    print join("\t",
        $langname,
        join('; ', sort { $a cmp $b } keys %{$txt_degr{uid}{$txt_degr} || {}}),
        join('; ', sort { $a cmp $b } keys %{$txt_degr{iso}{$txt_degr} || {}}),
        join('; ', sort { $a cmp $b } keys %{$txt_degr{glotto}{$txt_degr} || {}}),
    ), "\n";
}
