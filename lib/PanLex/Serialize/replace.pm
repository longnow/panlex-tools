#'replace'      => { cols => [1, 2], old => '⫷fail⫸', new => '⫷ex⫸' },
# Retags a tag in a tab-delimited source file.
# Arguments:
#   cols:     array of columns to be processed.
#   old:      regex matching any string(s) to be replaced.
#   new:      new string to use.

package PanLex::Serialize::replace;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/replace/;

sub replace {
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

            die "column $i not present in line" unless defined $col[$i];

            $col[$i] =~ s/$oldtag/$newtag/g;
            # replace the old tag(s) with the new one.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;