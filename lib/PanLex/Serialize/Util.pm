package PanLex::Serialize::Util;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IO => ':raw :encoding(utf8)';
use parent 'Exporter';
use File::Spec::Functions;

our @EXPORT = qw/load_wc parse_specs/;

sub load_wc {
    my $wctxt = -e 'wc.txt' ? 'wc.txt' : catfile($ENV{PANLEX_TOOLDIR}, 'serialize', 'data', 'wc.txt');

    open my $fh, '<', $wctxt or die $!;
    # Open the wc file for reading.

    my $wc;

    while (my $line = <$fh>) {
    # For each line of the wc file:

        chomp $line;
        # Delete its trailing newline.

        my @col = split /\t/, $line, -1;
        # Identify its columns.

        $wc->{$col[0]} = [ split /:/, $col[1] ];
        # Add it to the table of wc conversions.
    }
    
    close $fh;

    return $wc;
}

sub parse_specs {
    my ($specs) = @_;

    my %col_uid;

    foreach my $spec (@$specs) {
        my ($col, $uid) = split /:/, $spec;
        $col_uid{$col} = $uid;
    }

    return \%col_uid;
}

1;