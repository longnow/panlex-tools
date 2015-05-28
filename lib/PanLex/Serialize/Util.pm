package PanLex::Serialize::Util;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use File::Spec::Functions;

our @EXPORT = qw/parse_specs/;

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