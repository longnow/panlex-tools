# Tags all expressions and all intra-column meaning changes in a tab-delimited source file,
# disregarding any definitional parts.
# Arguments:
#	0: synonym delimiter (regular expression), or blank if none.
#	1: meaning delimiter (regular expression), or blank if none.
#	2: expression tag.
#	3: meaning tag.
#	4+: columns containing expressions.

package PanLex::Serialize::extag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variables, etc. except references.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

sub process {
    my ($in, $out, $exdelim, $mndelim, $extag, $mntag, @excol) = @_;
    
    # For each line of the input file:
    while (<$in>) {
    	chomp;
    	# Delete its trailing newline.        

    	my @col = (split /\t/, $_, -1);
    	# Identify its columns.

    	foreach my $i (@excol) {
    	# For each expression column:

    		$col[$i] =~ s/$exdelim/$extag/g if length $exdelim;
    		# Convert each expression delimiter in it to an expression tag, if expression
    		# delimiters exist.

    		$col[$i] =~ s/$mndelim/$mntag$extag/g if (length $mndelim);
    		# Convert each meaning delimiter in it to a meaning tag and an expression tag,
    		# if meaning delimiters exist.

    		$col[$i] = "$extag$col[$i]" if length $col[$i] && $col[$i] !~ /^(?:$extag|$mntag)/;
    		# Prefix an expression tag to the column, if not blank and not already
    		# containing a leading expression or meaning tag.

    		$col[$i] =~ s/$extag(?=$extag|$mntag|$)//g;
    		# Delete all expression tags with blank contents.

    		$col[$i] =~ s/$mntag(?=$mntag|$)//g;
    		# Delete all meaning tags with blank contents.
    	}

    	print $out join("\t", @col), "\n";
    	# Output the line.
    }
}

1;