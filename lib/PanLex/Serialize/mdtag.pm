# Tags metadata in a tab-delimited source file.
# Arguments:
#   col:   column containing metadata.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.

package PanLex::Serialize::mdtag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::replace;
use PanLex::Serialize::dpptag;

our @EXPORT = qw/mdtag/;

my %VARMAP = (
);

sub mdtag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my ($mdcol, $mdtag);
    
    if (ref $args eq 'HASH') {
        $mdcol    = $args->{col};
        $mdtag    = $args->{mdtag} // '⫷md:gram⫸';      
    } else {
        ($mdcol, $mdtag) = @$args;
    }
    validate_col($mdcol);

    my $var;

    if ($mdtag =~ /^⫷md:(.+)⫸$/) {
        die "don't know how to convert old md var: $1" unless exists $VARMAP{$1};
        $var = $VARMAP{$1};
    } else {
        die "don't know how to convert old mdtag: $mdtag";
    }

    my $temp;

    open my $fh, '>:encoding(utf8)', \$temp or die $!;
    replace($in, $fh, { cols => [$mdcol], from => '^', to => $var });
    close $fh;

    open $fh, '<:encoding(utf8)', \$temp or die $!;
    dpptag($fh, $out, { cols => [$mdcol] });
    close $fh;
}

1;