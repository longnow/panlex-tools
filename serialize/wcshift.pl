# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file.
# Arguments:
#	0: column containing prepended word class specifications.
#	1: start of word-class specification.
#	2: end of word-class specification.
#	3: word-classification tag.
#	4: expression tag.
#	5: regular expression matching any post-tag character.

package PanLex::Serialize::wcshift;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

sub process {
    my ($in, $out, $wccol, $wcstart, $wcend, $wctag, $extag, $post) = @_;
    
    while (<$in>) {
    # For each line of the input file:

    	chomp;
    	# Delete its trailing newline.

    	@col = (split /\t/, $_, -1);
    	# Identify its columns.

    	$col[$wccol] =~ s/$extag$wcstart(.+?)$wcend($post+)/$extag$2$wctag$1/g;
    	# Replace all word class specifications prepended to expressions with post-ex wc tags.

    	$col[$wccol] =~ s/$wcstart(.+?)$wcend//g;
    	# Delete all other word class specifications, including those prepended to definitions.

    	print $out join("\t", @col), "\n";
    	# Output the line.
    }    
}

1;