#'wcshift'      => { col => 2 },
# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file.
# Arguments:
#   col:      column containing prepended word class specifications.
#   pretag:   start of word-class specification. default '⫷wc:'.
#   posttag:  end of word-class specification. default '⫸'.
#   wctag:    word-classification tag. default '⫷wc⫸'.
#   extag:    expression tag. default '⫷ex⫸'.
#   postre:   regex matching any post-tag character. default '[^⫷]'.

package PanLex::Serialize::wcshift;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';

our @EXPORT = qw/wcshift/;

use PanLex::Validation;

sub wcshift {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($wccol, $pretag, $posttag, $wctag, $extag, $postre);
    
    if (ref $args eq 'HASH') {      
        $wccol    = $args->{col};
        $pretag   = $args->{pretag} // '⫷wc:';
        $posttag  = $args->{posttag} // '⫸';
        $wctag    = $args->{wctag} // '⫷wc⫸';
        $extag    = $args->{extag} // '⫷ex⫸';
        $postre   = $args->{postre} // '[^⫷]';
    } else {
        ($wccol, $pretag, $posttag, $wctag, $extag, $postre) = @$args;
    }
        
    validate_col($wccol);

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $wccol not present in line" unless defined $col[$wccol];

        $col[$wccol] =~ s/$extag$pretag(.+?)$posttag($postre+)/$extag$2$wctag$1/g;
        # Replace all word class specifications prepended to expressions with post-ex wc tags.

        $col[$wccol] =~ s/$pretag(.+?)$posttag//g;
        # Delete all other word class specifications, including those prepended to definitions.

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;