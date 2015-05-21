package PanLex::Client::Normalize;
use strict;
use parent 'Exporter';
use PanLex::Client;

our @EXPORT = qw/panlex_norm/;

#### panlex_norm
# Iteratively query the PanLex api at /norm and return the results.
# Arguments:
#   0: norm type ('ex' or 'df').
#   1: variety UID.
#   2: tt parameter containing expression texts (arrayref).
#   3: degrade parameter (boolean).
#   4: ap parameter (arrayref).

sub panlex_norm {
    my ($type, $uid, $tt, $degrade, $ap) = @_;
    my $result = {};
        
    for (my $i = 0; $i < @$tt; $i += $PanLex::Client::ARRAY_MAX) {
        my $last = $i + $PanLex::Client::ARRAY_MAX - 1;
        $last = $#{$tt} if $last > $#{$tt};
        
        # get the next set of results.
        my $this_result = panlex_query("/norm/${type}/$uid", { 
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