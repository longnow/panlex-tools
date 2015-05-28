package PanLex::Serialize::pptag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/pptag/;
our @EXPORT_OK = qw/pptag_item/;

sub pptag {
    my ($in, $out, $args) = @_;

    validate_cols($args->{cols});

    my @ppcol   = @{$args->{cols}};
    my $tag     = $args->{tag};
    my $delim   = $args->{delim} // '';
    my $prefix  = $args->{prefix} // '';
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.        

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@ppcol) {
            die "column $i not present in line" unless defined $col[$i];

            next unless length $col[$i];
            # Skip the column if it is blank.

            my @ppseg = $delim eq '' ? ($col[$i]) : split /$delim/, $col[$i];
            # Identify a list of properties in this column.

            foreach my $pp (@ppseg) {
                $pp = $prefix . $pp;
                # Apply the prefix (if any) to the segment.

                $pp = pptag_item($tag, $pp);
                # Tag the property.

            }

            $col[$i] = join '', @ppseg;
            # Identify the tagged column.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

sub pptag_item {
    my ($tag, $pp) = @_;

    die "property does not begin with a UID and delimiter: $pp"
        unless $pp =~ /^[a-z]{3}-\d{3}./;

    my $delim = substr($pp, 7, 1);
    # Identify the within-property delimiter as the first character following the UID.

    my @seg = split /$delim/, $pp;

    die "invalid number of segments in property: $pp" unless @seg == 3;

    $pp = "⫷$tag:$seg[0]⫸$seg[1]⫷$tag⫸$seg[2]";

    return $pp;    
}

1;