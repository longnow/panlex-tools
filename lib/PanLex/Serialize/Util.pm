package PanLex::Serialize::Util;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use File::Spec::Functions;

our @EXPORT = qw/parse_specs parse_tags combine_complex_tags serialize_tags serialize_tag tags_match tag_type/;

# takes an arrayref of column-uid specifications and returns a hashref whose 
# keys are column indexes and values are uids.
sub parse_specs {
    my ($specs) = @_;

    my %col_uid;

    foreach my $spec (@$specs) {
        my ($col, $uid) = split /:/, $spec;
        $col_uid{$col} = $uid;
    }

    return \%col_uid;
}

# takes a string containing standard tags and parses them into an arrayref
# containing one arrayref per tag. each tag arrayref contains three elements:
# the tag type, the uid (undef if none), and the tag content.
sub parse_tags {
    my ($str) = @_;

    my @tags;

    while ($str =~ /⫷([a-z0-9]+)(?::([a-z]{3}-\d{3}))?⫸([^⫷]*)/g) {
        push @tags, [ $1, $2, $3 ];
    }

    return \@tags;
}

# takes the output of parse_tags and combines complex tags 
# (dcs2, mcs2, dpp, and mpp) into two-element arrayrefs. 
sub combine_complex_tags {
    my ($tags) = @_;

    for (my $i = 0; $i < @$tags; $i++) {
        if ($tags->[$i][0] =~ /^([dm]cs2|[dm]pp)$/) {
            my $type = $1;
            $type =~ s/2$//;

            if ($i+1 < @$tags and $tags->[$i+1][0] eq $type) {
                $tags->[$i] = [ $tags->[$i], $tags->[$i+1] ];
                splice @$tags, $i+1, 1;
            }
        }
    }

    return $tags;
}

# serializes the output of parse_tags back into a standardly tagged string.
# arrayrefs of arrayrefs are flattened one level deep. tags whose type is
# undefined or '' are ignored.
sub serialize_tags {
    my ($tags) = @_;

    my $str = '';

    foreach my $tag (map { ref $_->[0] eq 'ARRAY' ? @$_ : $_ } @$tags) {
        next if !defined $tag->[0] || $tag->[0] eq '';

        $str .= "⫷$tag->[0]";
        $str .= ":$tag->[1]" if defined $tag->[1];
        $str .= "⫸$tag->[2]";
    }

    return $str;
}

# serializes a single tag.
sub serialize_tag {
    my ($tag) = @_;

    my $str = '';
    $str .= "⫷$tag->[0]";
    $str .= ":$tag->[1]" if defined $tag->[1];
    $str .= "⫸$tag->[2]";

    return $str;
}

# returns true if the two passed parsed tag arrayrefs match in both
# type and uid (if any), otherwise returns false.
# the optional third argument specifies a uid that will cause a match
# if (and only if) the first tag has the uid of the third argument and
# the second tag has no uid.
sub tags_match {
    my ($x, $y, $uid_loose_match) = @_;

    return 0 if $x->[0] ne $y->[0];
    return 1 if defined $uid_loose_match && defined $x->[1] && !defined $y->[1] && $x->[1] eq $uid_loose_match;
    return 0 if defined $x->[1] != defined $y->[1];
    return 0 if defined $x->[1] && $x->[1] ne $y->[1];
    return 1;
}

# returns the type of a tag.
sub tag_type {
    my ($tag) = @_;
    $tag = $tag->[0] if ref $tag->[0] eq 'ARRAY';
    return $tag->[0];
}

1;