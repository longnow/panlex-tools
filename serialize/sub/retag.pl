#'retag'      => { cols => [1, 2], oldtag => '⫷fail⫸', newtag => '⫷ex⫸' },
# Retags a tag in a tab-delimited source file.
# Arguments:
#   cols:     array of columns to be retagged.
#   oldtag:   regex matching any tag(s) to be retagged.
#   newtag:   new tag to use.

package PanLex::Serialize::retag;

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

    my (@retagcol, $oldtag, $newtag);
    
    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @retagcol    = @{$args->{cols}};
        $oldtag      = $args->{oldtag};
        $newtag      = $args->{newtag};
    } else {
        die "array arguments are not supported";
    }

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@retagcol) {
        # For each column to be retagged:

            $col[$i] =~ s/$oldtag/$newtag/g;
            # replace the old tag(s) with the new one.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;