package PanLex::Normalize;
use strict;
use base 'Exporter';
use Unicode::Normalize;

use vars qw/@EXPORT/;
@EXPORT = qw/norm_ex/;

my %UID;

foreach my $pm (glob(__FILE__ =~ s/\.pm$//r . '/*.pm')) {
    if ($pm =~ m|/[a-z]{3}\d{3}\.pm$|) {
        $UID{$1} = 1;
        require $pm;
    }
}

sub norm_ex {
    my ($str, $uid) = @_;
    my $module = 'PanLex::Normalize::' . $uid =~ s/-//r;
    return $module->norm($str);
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

1;