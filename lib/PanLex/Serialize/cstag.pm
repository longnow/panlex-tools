package PanLex::Serialize::cstag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Serialize::cstag;
use PanLex::Validation;

our @EXPORT = qw/cstag/;

sub cstag {
    my ($in, $out, $args) = @_;

    my ($cscol, $tag) = ($args->{cols}, $args->{tag});
    validate_cols($cscol);
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.        

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@$cscol) {
            die "column $i not present in line" unless defined $col[$i];

            next unless length $col[$i];
            # skip the column if it is blank.

            my $delim = substr($col[$i], 7, 1);
            # identify the column delimiter as the first character following the UID.

            my @seg = split /$delim/, $col[$i];

            die "invalid number of segments in column $i: $col[$i]" unless @seg >= 2 && @seg <= 4;
            validate_uid($seg[0]);

            if (@seg == 2) {
                $col[$i] = "⫷${tag}1:$seg[0]⫸$seg[1]";
            } elsif (@seg == 3) {
                $col[$i] = "⫷${tag}2:$seg[0]⫸$seg[1]⫷${tag}⫸$seg[2]";
            } else {
                validate_uid($seg[2]);
                $col[$i] = "⫷${tag}2:$seg[0]⫸$seg[1]⫷${tag}:$seg[2]⫸$seg[3]";
            }
            # tag the column.
        } 

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;