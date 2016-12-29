#!/usr/bin/env perl
use strict;
use warnings;
use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Client;
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

my @ISO_UID = qw( art-001 art-002 art-003 art-005 art-015 );
my $GLOTTO_UID = 'art-327';

my (@langnames, %langname_td, %td);

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

print STDERR "generating text degradations of languge names ...\n";
my $data = panlex_query('/td', { tt => \@langnames });

foreach my $langname (keys %{$data->{td}}) {
    $langname_td{$langname} = $data->{td}{$langname};
}

print STDERR "looking up all PanLex language variety default names ...\n";
$data = panlex_query_all('/lv', {});

foreach my $lv (@{$data->{result}}) {
    push @{$td{uid}{$lv->{td}}}, $lv->{uid};
}

print STDERR "looking up ISO 639 codes and Glottocodes corresponding to language names ...\n";
$data = panlex_query_all('/ex', {
    uid => [ @ISO_UID, $GLOTTO_UID ],
    trtd => \@langnames,
    include => ['trtd','uid'],
});

foreach my $ex (@{$data->{result}}) {
    my $type = $ex->{uid} eq $GLOTTO_UID ? 'glotto' : 'iso';
    push @{$td{$type}{$ex->{trtd}}}, $ex->{tt};
}

print STDERR "done.\n\n";

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
