package PanLex::Client::Normalize;
use strict;
use base 'Exporter';
use PanLex::Client;

use vars qw/@EXPORT/;
@EXPORT = qw/panlex_norm_ex/;

#### panlex_norm
# Iteratively query the PanLex api at /norm and return the results.
# Arguments:
#   0: variety UID.
#   1: tt parameter containing expression texts (arrayref).
#   2: degrade parameter (boolean).
#   3: ap parameter (arrayref).

sub panlex_norm_ex {
    my ($uid, $tt, $degrade, $ap) = @_;
    my $result = {};
        
    for (my $i = 0; $i < @$tt; $i += $PanLex::Client::ARRAY_MAX) {
        my $last = $i + $PanLex::Client::ARRAY_MAX - 1;
        $last = $#{$tt} if $last > $#{$tt};
        
        # get the next set of results.
        my $this_result = panlex_query("/norm/ex/$uid", { 
            tt => [@{$tt}[$i .. $last]],
            ap => $ap || [],
            degrade => $degrade,
            cache => 0,
        });
        
        # merge with the previous results, if any.
        $result = { %$result, %{$this_result->{norm}} };
    }
    
    return $result;
}

1;