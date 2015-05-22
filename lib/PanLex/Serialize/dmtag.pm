# Tags domain expressions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing metadata.
#   delim:  inter-expression delimiter, or '' if none. default '‣'.

package PanLex::Serialize::dmtag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::replace;
use PanLex::Serialize::mcstag;

our @EXPORT = qw/dmtag/;

sub dmtag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@dmcol, $delim);

    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @dmcol    = @{$args->{cols}};
        $delim    = $args->{delim} // '‣';      
    } else {
        (undef, $delim, @dmcol) = @$args;
        validate_cols(\@dmcol);
    }
    
    my $temp;

    open my $fh, '>:encoding(utf8)', \$temp or die $!;
    replace($in, $fh, { cols => \@dmcol, from => "^|$delim\\K", to => 'art-300⁋HasContext⁋' });
    close $fh;

    open $fh, '<:encoding(utf8)', \$temp or die $!;
    mcstag($fh, $out, { cols => \@dmcol, delim => $delim });
    close $fh;
}

1;