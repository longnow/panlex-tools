#'replace'      => { cols => [1, 2], from => '⫷fail⫸', to => '⫷ex⫸' },
# Replaces strings in a tab-delimited source file.
# Arguments:
#   cols:   array of columns to be processed.
#   from:   regex matching any string(s) to be replaced.
#   to:     new string to use.

package PanLex::Serialize::replace;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/replace retag/;

sub replace {
    my ($in, $out, $args) = @_;
    
    validate_cols($args->{cols});

    my @replacecol  = @{$args->{cols}};
    my $from        = $args->{from};
    my $to          = $args->{to};

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@replacecol) {
        # For each column to be processed:

            die "column $i not present in line" unless defined $col[$i];

            $col[$i] =~ s/$from/$to/g;
            # replace the old string(s) with the new one.

        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

# backwards compat
sub retag {
    my ($in, $out, $args) = @_;

    replace($in, $out, { cols => $args->{cols}, from => $args->{oldtag}, to => $args->{newtag} });
}

1;