# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#	0: definition tag.
#	1+: columns containing definitions.

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.


sub dftag {
    my ($in, $out, $dftag, @dfcol) = @_;
    
    while (<$in>) {
    # For each line of the input file:

    	chomp;
    	# Delete its trailing newline.

    	my @col = (split /\t/, $_, -1);
    	# Identify its columns.

    	foreach my $i (@dfcol) {
    	# For each definition column:

    		$col[$i] = "$dftag$col[$i]" if length $col[$i];
    		# Prefix a definition tag to the column, if not blank.
    	}

    	print $out join ("\t", @col), "\n";
    	# Output the line.
    }    
}

[\&dftag];
