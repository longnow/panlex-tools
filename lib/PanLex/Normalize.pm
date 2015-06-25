package PanLex::Normalize;
use strict;
use utf8;
use Unicode::Normalize;
use File::Spec::Functions;

my %UID;

{
    my $basename = __FILE__ =~ s/\.pm$//r;

    foreach my $pm (glob(catfile($basename, '*.pm'))) {
        if ($pm =~ m|/([a-z]{3}\d{3})\.pm$|) {
            $UID{$1} = 1;
            require $pm;
        }
    }
}

sub text {
    my ($self, $str, $uid) = @_;
    $uid =~ s/-//;

    if ($UID{$uid}) {
        my $module = "PanLex::Normalize::$uid";
        return $module->text($str);
    }
    else {
        return $str;
    }
}

sub strip_all_accents {
    my ($self, $str) = @_;
    $str = NFD($str);
    $str =~ s/\p{M}//g;
    return NFC($str);
}

sub strip_specified_accents {
    my ($self, $str, $accents) = @_;
    $str = NFD($str);
    $str =~ s/[$accents]//g;
    return NFC($str);
}

sub convert_chars {
    my ($self, $str, $from, $to) = @_;
    $str = NFD($str);
    eval "\$str =~ tr/$from/$to/";
    return NFC($str);
}

1;