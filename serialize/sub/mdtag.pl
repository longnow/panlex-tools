# Tags metadata in a tab-delimited source file.
# Arguments:
#    0: column containing metadata.
#    1: metadatum tag.

package PanLex::Serialize::mdtag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub process {
    my ($in, $out, $args) = @_;
    
    validate_hash($args);
    
    my $mdcol   = $args->{col};
    my $mdtag   = defined $args->{mdtag} ? $args->{mdtag} : '⫷md:gram⫸';

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