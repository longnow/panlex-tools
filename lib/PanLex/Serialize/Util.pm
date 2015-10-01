package PanLex::Serialize::Util;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use File::Spec::Functions;

our @EXPORT = qw/parse_specs parse_tags serialize_tags tags_match/;

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
    my ($str, $combine_complex_tags) = @_;

    my @tags;

    while ($str =~ /⫷([a-z0-9]+)(?::([a-z]{3}-\d{3}))?⫸([^⫷]*)/g) {
        push @tags, [ $1, $2, $3 ];
    }

    if ($combine_complex_tags) {
        for (my $i = 0; $i < @tags; $i++) {
            if ($tags[$i][0] =~ /^([dm]cs2|[dm]pp)$/) {
                my $type = $1;
                $type =~ s/2$//;

                if ($i+1 < @tags and $tags[$i+1][0] eq $type) {
                    $tags[$i] = [ $tags[$i], $tags[$i+1] ];
                    splice @tags, $i+1, 1;
                }
            }
        }
    }

    return \@tags;
}

sub serialize_tags {
    my ($tags) = @_;

    my $str = '';

    foreach my $tag (map { ref $_ eq 'ARRAY' ? @$_ : $_ } @$tags) {
        my ($type, $uid, $content) = @$tag;

        $str .= "⫷$type";
        $str .= ":$uid" if defined $uid;
        $str .= "⫸$content";
    }

    return $str;
}

sub tags_match {
    my ($x, $y) = @_;

    return 0 if $x->[0] ne $y->[0];
    return 0 if defined $x->[1] != defined $y->[1];
    return 0 if defined $x->[1] && $x->[1] ne $y->[1];
    return 1;
}

1;