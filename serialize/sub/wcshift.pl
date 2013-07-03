# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file.
# Arguments:
#    0: column containing prepended word class specifications.
#    1: start of word-class specification.
#    2: end of word-class specification.
#    3: word-classification tag.
#    4: expression tag.
#    5: regular expression matching any post-tag character.

package PanLex::Serialize::wcshift;

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

    my $wccol   = $args->{col};
    my $pretag  = defined $args->{pretag} ? $args->{pretag} : '⫷wc:';
    my $posttag = defined $args->{posttag} ? $args->{posttag} : '⫸';
    my $wctag   = defined $args->{wctag} ? $args->{wctag} : '⫷wc⫸';
    my $extag   = defined $args->{extag} ? $args->{extag} : '⫷ex⫸';
    my $postre  = defined $args->{postre} ? $args->{postre} : '[^⫷]';
    
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