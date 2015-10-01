package PanLex::Serialize::Util;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use File::Spec::Functions;

our @EXPORT = qw/parse_specs parse_tags deparse_tags/;

sub parse_specs {
    my ($specs) = @_;

    my %col_uid;

    foreach my $spec (@$specs) {
        my ($col, $uid) = split /:/, $spec;
        $col_uid{$col} = $uid;
    }

    return \%col_uid;
}

sub parse_tags {
    my ($str) = @_;

    my @tags;

    while ($str =~ /⫷([a-z0-9]+)(?::([a-z]{3}-\d{3}))?⫸([^⫷]+)/g) {
        push @tags, [ $1, $2, $3 ];
    }

    return \@tags;
}

sub deparse_tags {
    my ($tags) = @_;

    my $str = '';

    foreach my $tag (@$tags) {
        my ($type, $uid, $content) = @$tag;

        $str .= "⫷$type";
        $str .= ":$uid" if defined $uid;
        $str .= "⫸$content";
    }

    return $str;
}

1;