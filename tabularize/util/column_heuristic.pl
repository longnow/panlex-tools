use strict;
use utf8;
use List::Util qw/max min/;
use Statistics::Basic qw/median/;

# the number of positions to look (left and right) in each
# successive iteration while refining the heuristic.
my $LOOK_RANGE = 10;

# the minimum width of a column. candidate heuristics with columns
# smaller than this will be discarded.
my $MIN_WIDTH = 5;

# returns the cumulative score for position $pos in $lines.
# by default, gives a score of 1 for each space. modify as needed.
sub score_pos {
    my ($lines, $pos, $maxwidth) = @_;
    
    my $score = 0;
    
    foreach my $line (@$lines) {        
        if (substr($line,$pos,1) eq ' ') {
            # ignore cases where there is nothing but whitespace to one side, as this
            # is not informative for the location of a column boundary.
            next if substr($line, 0, $pos) =~ /^\s+$/;
            next if substr($line, $pos+1) =~ /^\s+$/;

            $score++;
            #$score += 5 * count_adjacent_spaces($line, $pos, $maxwidth) / $maxwidth;
        }
    }
    
    $score = int($score);
        
    return $score;
}

sub count_adjacent_spaces {
    my ($line, $pos, $maxwidth) = @_;
    my $count = 0;
    
    for (my $i = $pos - 1; $i >= 0 && substr($line,$i,1) eq ' '; $i--) {
        $count++;
    }        
    
    for (my $i = $pos + 1; $i < $maxwidth && substr($line,$i,1) eq ' '; $i++) {
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
    
    my @len = map { length } @$lines;
    my $maxwidth = max(@len);
    
    foreach my $line (@$lines) {
        $line .= ' ' x ($maxwidth - length $line) if length $line < $maxwidth;
    }
    
    my @candidates = 
        grep { valid_candidate($_) }
        map { _column_heuristic($num, $lines, $maxwidth, $_) } (median(@len), $maxwidth);
    
    die "could not find any candidate heuristics" unless @candidates;
    
    return [0, @{$candidates[0]} ];
}

sub _column_heuristic {
    my ($num, $lines, $maxwidth, $linewidth) = @_;

    my $h = [];
    
    my $startwidth = int($linewidth / $num);
    for my $i (1 .. $num - 1) {
        push @$h, $startwidth * $i;        
    }

    my %seen;
    $seen{hash_heuristic($h)}++;
        
    while (1) {
        my $newh = refine_heuristic($h, $lines, $maxwidth);
                
        my $diff = 0;
        for (my $i = 0; $i < $num; $i++) {
            $diff += abs($h->[$i] - $newh->[$i]);
        }
        
        $h = $newh;
        my $hash = hash_heuristic($h);
        $seen{$hash}++;
        
        last if $diff == 0 || $seen{$hash} > 5;
    }
    
    return $h;
}

sub refine_heuristic {
    my ($h, $lines, $maxwidth) = @_;
    $h = [@$h];
    
    foreach my $pos (@$h) {
        my @try_pos = ($pos);
        for my $i (1 .. $LOOK_RANGE) {
            push @try_pos, $pos - $i, $pos + $i;            
        }
        @try_pos = grep { $_ >= 0 && $_ < $maxwidth } @try_pos;
        
        my %score = map { $_ => score_pos($lines, $_, $maxwidth) } @try_pos;
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

sub valid_candidate {
    my ($h) = @_;
    
    return 0 if $h->[0] < $MIN_WIDTH;
    
    for (my $i = 1; $i < @$h; $i++) {
        return 0 if $h->[$i] - $h->[$i-1] < $MIN_WIDTH;
    }
    
    return 1;
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

1;