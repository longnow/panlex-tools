# Tags metadata in a tab-delimited source file.
# Arguments:
#	0: column containing metadata.
#	1: metadatum tag.

package PanLex::Serialize::mdtag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

sub process {
    my ($in, $out, $mdcol, $mdtag) = @_;
    
    while (<$in>) {
    # For each line of the input file:

    	chomp;
    	# Delete its trailing newline.

    	my @col = split /\t/, $_, -1;
    	# Identify its columns.

    	$col[$mdcol] = "$mdtag$col[$mdcol]" if length $col[$mdcol];
    	# Prefix a meaning-identifier tag to the meaning-identifier column's content,
    	# if not blank.

    	print $out join("\t", @col), "\n";
    	# Output the line.
    }    
}

1;