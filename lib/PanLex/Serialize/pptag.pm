package PanLex::Serialize::pptag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/pptag/;

sub pptag {
    my ($in, $out, $args) = @_;

    my ($ppcol, $tag) = ($args->{cols}, $args->{tag});
    validate_cols($ppcol);
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.        

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@$ppcol) {
            die "column $i not present in line" unless defined $col[$i];

            next unless length $col[$i];
            # skip the column if it is blank.

            die "column $i does not begin with a UID and delimiter: $col[$i]"
                unless $col[$i] =~ /^[a-z]{3}-\d{3}./;

            my $delim = substr($col[$i], 7, 1);
            # identify the column delimiter as the first character following the UID.

            my @seg = split /$delim/, $col[$i];

            die "invalid number of segments in column $i" unless @seg == 3;

            $col[$i] = "⫷$tag:$seg[0]⫸$seg[1]⫷$tag⫸$seg[2]";
            # tag the column.
        } 

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;