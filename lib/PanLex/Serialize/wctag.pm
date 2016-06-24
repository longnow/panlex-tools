#'wctag'        => { col => 1 },
# Converts and tags word classifications in a tab-delimited source file.
# Arguments:
#   col:   column containing word classifications.
#   wctag: word-classification tag. default '⫷wc⫸'.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.
#   log:   set to 1 to log unconvertible word classes to wc.log, 0 otherwise.
#            default 0.

package PanLex::Serialize::wctag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::csppmap;

our @EXPORT = qw/wctag/;

sub wctag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($wccol, $log);
    
    if (ref $args eq 'HASH') {
        $wccol  = $args->{col};
        $log    = $args->{log} // 1; 
    } else {
        ($wccol) = @$args;
        $log = 0;
    }

    validate_col($wccol);
    
    csppmap($in, $out, { cols => [$wccol], file => 'csppmap.txt', delim => '', log => $log });
}

1;