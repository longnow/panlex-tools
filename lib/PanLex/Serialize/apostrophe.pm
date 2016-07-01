# Converts a tab-delimited source file's apostrophes.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns possibly requiring apostrophe normalization.

package PanLex::Serialize::apostrophe;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Client;
use PanLex::Validation;
use PanLex::Serialize::Util;

our @EXPORT = qw(apostrophe);

sub apostrophe {
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

    my $col_uid = parse_specs(\@specs);
    my @uniq_uid = uniq(values %$col_uid);
    
    my $result = panlex_query_all('/lv', { uid => \@uniq_uid, include => 'cp' });
    
    my %apos;

    # Add data on the best apostrophe, making it U+02bc for varieties without any data on
    # editor-approved characters.
    foreach my $lv (@{$result->{result}}) {
        my $best;

        if (@{$lv->{cp}}) {
            my ($hpg, $slt, $mtc, $rq);

            foreach my $cp (@{$lv->{cp}}) {
                $hpg = 1 if $cp->[0] <= 0x05f3 && $cp->[1] >= 0x05f3; # Hebrew punctuation geresh
                $slt = 1 if $cp->[0] <= 0xa78c && $cp->[1] >= 0xa78c; # lowercase saltillo
                $mtc = 1 if $cp->[0] <= 0x02bb && $cp->[1] >= 0x02bb; # modifier letter turned comma
                $rq = 1 if $cp->[0] <= 0x2019 && $cp->[1] >= 0x2019; # right single quotation mark
                #$ma = 1 if $cp->[0] <= 0x02bc && $cp->[1] >= 0x02bc; # modifier letter apostrophe
            }
            
            if ($hpg) {
                $best = "\x{05f3}";
            }
            elsif ($slt) {
                $best = "\x{a78c}";
            }
            elsif ($mtc) {
                $best = "\x{02bb}";
            } 
            elsif ($rq) {
                $best = "\x{2019}";
            }
        }

        $apos{$lv->{uid}} = $best || "\x{02bc}";
    }

    if (@uniq_uid != keys %apos) {
        my @not_found;

        foreach my $uid (sort @uniq_uid) {
            push @not_found, $uid unless exists $apos{$uid};
        }

        die "could not find an apostrophe conversion for the following language varieties: "
            . join(', ', sort @not_found);
    }

    my @convertible_col = keys %$col_uid;

    while (<$in>) {
    # For each line of the input file:
        
        chomp;
        # Remove its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@convertible_col) {
        # For each column to be processed:

            die "column $i not present in line" unless defined $col[$i];

            $col[$i] =~ s/'/$apos{$col_uid->{$i}}/g;
            # Convert any apostrophes.

        }

        print $out join("\t", @col), "\n";
        # Output the modified line.
    }

}

sub uniq {
    my %seen;
    $seen{$_} = undef for @_;
    return keys %seen;
}

1;