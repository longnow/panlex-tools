package PanLex::Normalize;
use strict;
use utf8;
use Unicode::Normalize;

my %UID;

foreach my $pm (glob(__FILE__ =~ s/\.pm$//r . '/*.pm')) {
    if ($pm =~ m|/([a-z]{3}\d{3})\.pm$|) {
        $UID{$1} = 1;
        require $pm;
    }
}

sub ex {
    my ($self, $str, $uid) = @_;
    $uid =~ s/-//;

    if ($UID{$uid}) {
        my $module = "PanLex::Normalize::$uid";
        return $module->ex($str);
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