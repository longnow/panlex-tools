# Tags domain expressions in a tab-delimited source file.
# Arguments:
#	0: domain-expression tag.
#	1: inter-expression delimiter, or blank if none.
#	2+: columns containing domain expressions.

package PanLex::Serialize::dmtag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

sub process {
    my ($in, $out, $dmtag, $exdelim, @dmcols) = @_;
    
    while (<$in>) {
    # For each line of the input file:

    	my @col = (split /\t/, $_, -1);
    	# Identify its columns.

    	foreach my $i (@dmcols) {
    	# For each domain-expression column:

    		if (length $exdelim) {
    		# If there is an inter-expression delimiter:

    			$col[$i] =~ s/(^|$exdelim)(?!$|$exdelim)/$dmtag/g;
    			# Prefix each element of the column's value with a domain-expression tag.
    		}

    		else {
    		# Otherwise, i.e. if there is no inter-expression delimiter:

    			$col[$i] = "$dmtag$col[$i]";
    			# Prefix the column's value with a domain-expression tag.

    		}

    	}

    	print $out join ("\t", @col);
    	# Output the line.
    }    
}

[\&dmtag];