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
    
    my ($wccol, $pretag, $posttag, $wctag, $extag, $postre);
    
    if (ref $args eq 'HASH') {      
        $wccol    = $args->{col};
        $pretag   = defined $args->{pretag} ? $args->{pretag} : '⫷wc:';
        $posttag  = defined $args->{posttag} ? $args->{posttag} : '⫸';
        $wctag    = defined $args->{wctag} ? $args->{wctag} : '⫷wc⫸';
        $extag    = defined $args->{extag} ? $args->{extag} : '⫷ex⫸';
        $postre   = defined $args->{postre} ? $args->{postre} : '[^⫷]';
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

        $col[$wccol] =~ s/$extag$pretag(.+?)$posttag($postre+)/$extag$2$wctag$1/g;
        # Replace all word class specifications prepended to expressions with post-ex wc tags.

        $col[$wccol] =~ s/$pretag(.+?)$posttag//g;
        # Delete all other word class specifications, including those prepended to definitions.

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;