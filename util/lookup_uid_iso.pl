use strict;
use warnings;
use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Client;
use List::Util 'uniq';
binmode STDOUT, ':encoding(utf8)';

my @ISO_UID = qw( art-001 art-002 art-003 art-005 art-015 );

die "you must provide a filename (one language name per line)" unless @ARGV;

my ($filename) = @ARGV;
die "could not read file: $filename" unless -r $filename;

my (@langnames, %langname_td, %td_uid, %td_iso);

open my $fh, '<:crlf:encoding(utf-8)', $filename or die $!;

while (<$fh>) {
    chomp;
    push @langnames, $_;
}

close $fh;

my $data = panlex_query('/td', { tt => \@langnames });

foreach my $langname (keys %{$data->{td}}) {
    $langname_td{$langname} = $data->{td}{$langname};
}

$data = panlex_query_all('/lv', {});

foreach my $lv (@{$data->{result}}) {
    push @{$td_uid{$lv->{td}}}, $lv->{uid};
}

$data = panlex_query_all('/ex', {
    uid => \@ISO_UID,
    trtd => \@langnames,
    include => 'trtd',
});

foreach my $ex (@{$data->{result}}) {
    push @{$td_iso{$ex->{trtd}}}, $ex->{tt};
}

print join("\t", 'Name', 'PanLex UIDs', 'ISO 639 codes'), "\n";

foreach my $langname (@langnames) {
    my $td = $langname_td{$langname};

    my @info = ($langname);
    push @info, join('; ', sort { $a cmp $b } uniq @{$td_uid{$td} || []});
    push @info, join('; ', sort { $a cmp $b } uniq @{$td_iso{$td} || []});

    print join("\t", @info), "\n";
}
