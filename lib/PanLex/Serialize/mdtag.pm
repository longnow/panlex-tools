# Tags metadata in a tab-delimited source file.
# Arguments:
#   col:   column containing metadata.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.
#   delim: metadatum delimiter, or '' if none. default ''.

package PanLex::Serialize::mdtag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IO => ':raw :encoding(utf8)';
use parent 'Exporter';
use File::Spec::Functions;
use PanLex::Validation;
use PanLex::Serialize::dpptag;

our @EXPORT = qw/mdtag/;

my %varmap;

load_map();

sub mdtag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my ($mdcol, $mdtag, $delim);
    
    if (ref $args eq 'HASH') {
        $mdcol    = $args->{col};
        $mdtag    = $args->{mdtag} // '⫷md:gram⫸';
        $delim    = $args->{delim} // '';
    } else {
        ($mdcol, $mdtag) = @$args;
        $delim = '';
    }
    validate_col($mdcol);

    my $var;

    if ($mdtag =~ /^⫷md:(.+)⫸$/) {
        die "don't know how to convert old md var: $1" unless exists $varmap{$1};
        $var = $varmap{$1};
    } else {
        die "don't know how to convert old mdtag: $mdtag";
    }

    dpptag($in, $out, { cols => [$mdcol], delim => $delim, prefix => $var });
}

sub load_map {
    my $mapfile = 'mdvar.txt';

    $mapfile = catfile($ENV{PANLEX_TOOLDIR}, 'serialize', 'data', $mapfile)
        unless -e $mapfile;

    open my $mapin, '<', $mapfile or die $!;

    while (<$mapin>) {
        chomp;

        my ($from, $to) = split /\t/, $_, -1;
        next if $to eq '';

        $varmap{$from} = $to;
    }

    close $mapfile;
}

1;