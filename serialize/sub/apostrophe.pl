# Converts a tab-delimited source file's apostrophes.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns possibly requiring apostrophe normalization.

package PanLex::Serialize::apostrophe;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Client;
use PanLex::Validation;

sub process {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my @specs;
    
    if (ref $args eq 'HASH') {
        validate_specs($args->{specs});
        @specs = @{$args->{specs}};
    } else {
        @specs = @$args;
        validate_specs(\@specs);
    }

    my (@pcol, %col_uid, %apos);
    
    foreach my $spec (@specs) {
        my ($col, $uid) = split /:/, $spec;
        $col = int($col);
        push @pcol, $col;
        $col_uid{$col} = $uid;
    }
    
    my $result = panlex_query_all('/lv', { uid => [values %col_uid], include => 'cp' });
    
    # Add data on the best apostrophe, making it U+02bc for varieties without any data on
    # editor-approved characters.
    foreach my $lv (@{$result->{result}}) {
        my $best;
        if (@{$lv->{cp}}) {
            my ($rq, $ma, $mtc, $slt);

            foreach my $cp (@{$lv->{cp}}) {
                $rq = 1 if $cp->[0] <= 0x2019 && $cp->[1] >= 0x2019; # right single quotation mark
                $ma = 1 if $cp->[0] <= 0x02bc && $cp->[1] >= 0x02bc; # modifier letter apostrophe
                $mtc = 1 if $cp->[0] <= 0x02bb && $cp->[1] >= 0x02bb; # modifier letter turned comma
                $slt = 1 if $cp->[0] <= 0xa78c && $cp->[1] >= 0xa78c; # lowercase saltillo
            }
            
            if ($mtc) {
                $best = 'ʻ' unless $rq || $ma;
            } 
            else {
                if ($rq) {
                    $best = '’' unless $ma;
                }
                else {
                    $best = 'ʼ';
                }
            }
        }

        $apos{$lv->{uid}} = $best || 'ʼ';
    }

    my %noncon;

    while (<$in>) {
    # For each line of the input file:
        
        if (index($_, "'") > -1) {
        # If it contains any apostrophes:

            my @col = split /\t/, $_, -1;
            # Identify its columns.

            foreach my $i (@pcol) {
            # For each column to be processed:

                die "column $i not present in line" unless defined $col[$i];

                if (index($col[$i], "'") > -1) {
                # If it contains any apostrophes:

                    if (exists $apos{$col_uid{$i}}) {
                    # If its variety's apostrophes are convertible:

                        $col[$i] =~ s/'/$apos{$col_uid{$i}}/g;
                        # Convert them.
                    }

                    else {
                    # Otherwise, i.e. if its variety's apostrophes are not convertible:

                        $noncon{$i} = '';
                        # Add the column to the table of columns containing nonconvertible
                        # apostrophes, if not already in it.
                    }
                }
            }

            $_ = join "\t", @col;
            # Save the modified line.
        }

        print $out $_;
        # Output the line.
    }

    if (keys %noncon) {
    # If any column contained nonconvertible apostrophes:

        warn (
            'Could not convert apostrophes found in column(s) '
            . join(', ', sort { $a <=> $b } keys %noncon) . "\n"
        );
        # Report them.
    }
}

1;