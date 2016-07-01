package PanLex::Serialize::cstag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw(cstag);
our @EXPORT_OK = qw(cstag_item);

sub cstag {
    my ($in, $out, $args) = @_;

    validate_cols($args->{cols});

    my @cscol   = @{$args->{cols}};
    my $tag     = $args->{tag};
    my $delim   = $args->{delim} // '‣';
    my $prefix  = $args->{prefix} // '';
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.        

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@cscol) {
            die "column $i not present in line" unless defined $col[$i];

            next unless length $col[$i] && $col[$i] !~ /^⫷/;
            # Skip the column if it is blank or tagged.

            my @csseg = $delim eq '' ? ($col[$i]) : split /$delim/, $col[$i];
            # Identify a list of classifications in this column.

            foreach my $cs (@csseg) {
                $cs = $prefix . $cs;
                # Apply the prefix (if any) to the segment.

                $cs = cstag_item($tag, $cs);
                # Tag the classification.
            }

            $col[$i] = join '', @csseg;
            # Identify the tagged column.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }
}

sub cstag_item {
    my ($tag, $cs) = @_;

    die "classification does not begin with a UID and delimiter: $cs"
        unless $cs =~ /^[a-z]{3}-\d{3}./;

    my $delim = substr($cs, 7, 1);
    # Identify the within-classification delimiter as the first character following the UID.

    my @seg = split /$delim/, $cs;

    die "invalid number of segments in classification: $cs" unless @seg >= 2 && @seg <= 4;

    if (@seg == 2) {
        return "⫷${tag}1:$seg[0]⫸$seg[1]";
    } elsif (@seg == 3) {
        return "⫷${tag}2:$seg[0]⫸$seg[1]⫷${tag}⫸$seg[2]";
    } else {
        validate_uid($seg[2]);
        return "⫷${tag}2:$seg[0]⫸$seg[1]⫷${tag}:$seg[2]⫸$seg[3]";
    }
}

1;