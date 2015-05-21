# Tags metadata in a tab-delimited source file.
# Arguments:
#   col:   column containing metadata.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub mdtag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my ($mdcol, $mdtag);
    
    if (ref $args eq 'HASH') {
        $mdcol    = $args->{col};
        $mdtag    = $args->{mdtag} // '⫷md:gram⫸';      
    } else {
        ($mdcol, $mdtag) = @$args;
    }
    validate_col($mdcol);

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $mdcol not present in line" unless defined $col[$mdcol];
        # If the specified column does not exist or has an undefined value, quit and
        # report the error.

        $col[$mdcol] = "$mdtag$col[$mdcol]" if length $col[$mdcol];
        # Prefix a metadatum tag to the metadatum column's content, if not blank.

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;