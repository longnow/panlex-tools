use strict;
use utf8;
use List::Util qw/max min/;

# the number of positions to look (left and right) in each
# successive iteration while refining the heuristic.
my $LOOK_RANGE = 10;

# returns the cumulative score for position $pos in $lines.
# by default, gives a score of 1 for each space. modify as needed.
sub score_pos {
    my ($lines, $pos, $maxlen) = @_;
    
    my $score = 0;
    
    foreach my $line (@$lines) {
        if (substr($line,$pos,1) eq ' ') {
            $score++;
            #$score += 5 * count_adjacent_spaces($line, $pos, $maxlen) / $maxlen;
        }
    }
    
    $score = int($score);
        
    return $score;
}

sub count_adjacent_spaces {
    my ($line, $pos, $maxlen) = @_;
    my $count = 0;
    
    for (my $i = $pos - 1; $i >= 0 && substr($line,$i,1) eq ' '; $i--) {
        $count++;
    }
    for (my $i = $pos + 1; $i < $maxlen && substr($line,$i,1) eq ' '; $i++) {
        $count++;
    }
    
    return $count;
}

# generates a heuristic for the location of column breaks.
# Arguments:
#   $num:   the number of columns
#   $lines: arrayref containing text lines
# Returns: column heuristic, to be passed to heuristic_parse.
sub column_heuristic {
    my ($num, $lines) = @_;
    $lines = [@$lines];
    
    my $maxlen = max(map { length } @$lines);
    
    foreach my $line (@$lines) {
        $line .= ' ' x ($maxlen - length $line) if length $line < $maxlen;
    }
    
    my $h = [];
    
    my $start_width = int($maxlen / $num);
    for my $i (1 .. $num - 1) {
        push @$h, $start_width * $i;        
    }

    my %seen;
    $seen{hash_heuristic($h)}++;
        
    while (1) {
        my $newh = refine_heuristic($h, $lines, $maxlen);
                
        my $diff = 0;
        for (my $i = 0; $i < $num; $i++) {
            $diff += abs($h->[$i] - $newh->[$i]);
        }
        
        $h = $newh;
        my $hash = hash_heuristic($h);
        $seen{$hash}++;
        
        last if $diff == 0 || $seen{$hash} > 5;
    }
    
    return [0, @$h];
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

sub refine_heuristic {
    my ($h, $lines, $maxlen) = @_;
    $h = [@$h];
    
    foreach my $pos (@$h) {
        my @try_pos = ($pos);
        for my $i (1 .. $LOOK_RANGE) {
            push @try_pos, $pos - $i, $pos + $i;            
        }
        @try_pos = grep { $_ >= 0 && $_ < $maxlen } @try_pos;
        
        my %score = map { $_ => score_pos($lines, $_, $maxlen) } @try_pos;
        my $maxscore = max(values %score);
        my @candidates = grep { $score{$_} == $maxscore } @try_pos;
        my %distance = map { abs($_ - $pos) => $_ } @candidates;
        
        $pos = $distance{min(keys %distance)};
    }
    
    return $h;
}

sub hash_heuristic {
    my ($h) = @_;
    return join('|', map { sprintf "%04d", $_ } @$h);
}

1;