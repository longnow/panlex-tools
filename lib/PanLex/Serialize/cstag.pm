package PanLex::Serialize::cstag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/cstag/;

sub cstag {
    my ($in, $out, $args) = @_;

    validate_cols($args->{cols});

    my @cscol   = @{$args->{cols}};
    my $tag     = $args->{tag};
    my $delim   = $args->{delim} // '';
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.        

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@cscol) {
            die "column $i not present in line" unless defined $col[$i];

            next unless length $col[$i];
            # Skip the column if it is blank.

            my @csseg = $delim eq '' ? ($col[$i]) : split /$delim/, $col[$i];
            # Identify a list of classifications in this column.

            foreach my $cs (@csseg) {
                die "classification does not begin with a UID and delimiter: $cs"
                    unless $cs =~ /^[a-z]{3}-\d{3}./;

                my $delim2 = substr($cs, 7, 1);
                # Identify the within-classification delimiter as the first character following the UID.

                my @seg = split /$delim2/, $cs;

                die "invalid number of segments in classification: $cs" unless @seg >= 2 && @seg <= 4;

                if (@seg == 2) {
                    $cs = "⫷${tag}1:$seg[0]⫸$seg[1]";
                } elsif (@seg == 3) {
                    $cs = "⫷${tag}2:$seg[0]⫸$seg[1]⫷${tag}⫸$seg[2]";
                } else {
                    validate_uid($seg[2]);
                    $cs = "⫷${tag}2:$seg[0]⫸$seg[1]⫷${tag}:$seg[2]⫸$seg[3]";
                }
                # Tag the classification.

            }

            $col[$i] = join '', @csseg;
            # Identify the tagged column.

        } 

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;