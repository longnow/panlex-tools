# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing definitions.
#   dftag:  definition tag. default '⫷df⫸'.

package PanLex::Serialize::dftag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub process {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@dfcol, $dftag);

    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @dfcol    = @{$args->{cols}};
        $dftag    = $args->{dftag} // '⫷df⫸';      
    } else {
        ($dftag, @dfcol) = @$args;
        validate_cols(\@dfcol);
    }
    
    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@dfcol) {
        # For each definition column:

            die "column $i not present in line" unless defined $col[$i];

            $col[$i] = "$dftag$col[$i]" if length $col[$i];
            # Prefix a definition tag to the column, if not blank.
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;