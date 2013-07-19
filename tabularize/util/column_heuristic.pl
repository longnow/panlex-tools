use strict;
use utf8;
use List::Util qw/max min sum/;

# the number of positions to look (left and right) for candidate boundaries.
my $LOOK_RANGE = 15;

# the minimum width of a column. candidate columns with width smaller
# than this will be discarded.
my $MIN_WIDTH = 10;

# the maximum number of adjacent spaces to count towards a position's score.
my $MAX_ADJACENT = int($LOOK_RANGE/2);

# returns the cumulative score for position $pos in $lines. by default,
# gives a score of 1 for each space, plus a weighted score for some
# horizontally adjacent spaces (see count_adjacent_spaces).
sub score_pos {
    my ($lines, $pos, $maxwidth) = @_;
    
    my $score = 0;
    
    foreach my $line (@$lines) {        
        if (substr($line,$pos,1) eq ' ') {
            $score++;
            $score += 5 * count_adjacent_spaces($line, $pos, $maxwidth) / $maxwidth;
        }
    }
    
    $score = int($score);
    
    #print "$pos = $score\n";
        
    return $score;
}

sub count_adjacent_spaces {
    my ($line, $pos, $maxwidth) = @_;
    my $count = 0;
    
    my $str = substr($line,0,$pos-1);
    return 0 if $str =~ /^ +$/;
    $str =~ /( +)$/;
    $count += length $1;
    
    $str = substr($line, $pos+1);
    return 0 if $str =~ /^ +$/;
    $str =~ /^( +)/;
    $count += length $1;
    
    return min($count, $MAX_ADJACENT);
}

# generates a heuristic for the location of column breaks.
# Arguments:
#   $num:   the number of columns
#   $lines: arrayref containing text lines
# Returns: column heuristic, to be passed to heuristic_parse.
sub column_heuristic {
    my ($num, $lines) = @_;
    $lines = [@$lines];
    
    my @len = grep { $_ > 0 } map { length } @$lines;
    my $maxwidth = max(@len);
    
    foreach my $line (@$lines) {
        $line .= ' ' x ($maxwidth - length $line) if length $line < $maxwidth;
    }
    
    my %candidates = 
        map { $_->[1] => $_->[0] } # map score to candidate
        map { pick_heuristic($num, $lines, $maxwidth, $_) } 
            (median(@len), $maxwidth); # try two alternative starting points
    
    die "could not find any candidate heuristics" unless keys %candidates;
    
    # return the candidate with the highest score
    return [0, @{$candidates{max(keys %candidates)}} ];
}

# parses the columns from a line using a generated heuristic.
# Arguments:
#   $h:     heuristic returned by column_heuristic.
#   $line:  the line to parse.
# Returns: list of column values.
sub heuristic_parse {
    my ($h, $line) = @_;
    
    my @rec;
    for (my $i = 0; $i < @$h - 1; $i++) {
        push @rec, substr($line, $h->[$i], $h->[$i+1] - $h->[$i]);
    }
    push @rec, substr($line, $h->[-1]);
    
    return @rec;
}

sub pick_heuristic {
    my ($num, $lines, $maxwidth, $startwidth) = @_;

    my $h = [];
    
    my $startcolwidth = int($startwidth / $num);
    for my $i (1 .. $num - 1) {
        push @$h, $startcolwidth * $i;
    }
    
    # generate range of positions to try for each column boundary
    my @candidate_pos;
    foreach my $pos (@$h) {
        my @try_pos = ($pos);
        for my $i (1 .. $LOOK_RANGE) {
            push @try_pos, $pos - $i, $pos + $i;            
        }
        @try_pos = grep { $_ >= 0 && $_ < $maxwidth } @try_pos;
        push @candidate_pos, \@try_pos;
    }
    
    # generate all candidate boundary combinations
    my @candidates = ([]);
    for my $i (0 .. @$h - 1) {
        my @newcandidates;
        foreach my $c (@candidates) {
            foreach my $pos (@{$candidate_pos[$i]}) {
                push @newcandidates, [@$c, $pos];
            }
        }
        @candidates = @newcandidates;
    }

    # select only the valid combinations according to MIN_WIDTH
    @candidates = grep { valid_candidate($_, $maxwidth) } @candidates;
        
    my %score;
    foreach my $c (@candidates) {
        my $s = sum(map { score_pos($lines, $_, $maxwidth) } @$c);
        push @{$score{$s}}, $c;
    }

    my %distance;
    my $maxscore = max(keys %score);
    foreach my $toph (@{$score{$maxscore}}) {        
        my $d = 0; 
        for (my $i = 0; $i < @$toph; $i++) {
            $d += abs($toph->[$i] - $h->[$i]);
        }
        
        $distance{$d} = $toph;
    }
    
    my $besth = $distance{min(keys %distance)};

    #print "starting point\n", Dumper($h), "\n";
    #print "\nresult\n", Dumper([$besth, $maxscore]), "\n";

    return [$besth, $maxscore];
}

sub valid_candidate {
    my ($h, $maxwidth) = @_;
    
    return 0 if $h->[0] < $MIN_WIDTH;
    
    for (my $i = 1; $i < @$h; $i++) {
        return 0 if $h->[$i] - $h->[$i-1] < $MIN_WIDTH;
    }
    
    return 0 if $maxwidth - $h->[-1] - 1 < $MIN_WIDTH;
    
    return 1;
}

sub median {
    my @vals = sort { $a <=> $b } @_;
    my $len = @vals;
    return $vals[int($len/2)] if $len % 2;
    return $vals[int($len/2)-1] + $vals[int($len/2)];
}

1;