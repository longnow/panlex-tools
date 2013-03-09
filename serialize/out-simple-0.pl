# Converts a normally tagged source file to a simple-text varilingual source file,
# eliminating duplicates.
# Arguments:
#	0+: specifications (column index and variety UID, colon-delimited) of columns
#		containing expressions.

package PanLex::Serialize::out_simple_0;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

$PanLex::Serialize::out_simple_0::final = 1;

sub process {
    my ($in, $out, @args) = @_;
    
    print $out ".\n0\n";
    # Output the file header.

    my (%all, %col);

    for (my $i = 0; $i < @args; $i++) {
    # For each expression column:

    	my @col = split /:/, $args[$i];
    	# Identify its specification parts.

    	$col{$col[0]} = $col[1];
    	# Add its index and variety UID to the table of expression columns.
    }

    while (<$in>) {
    # For each line of the input file:

    	chomp;
    	# Delete its trailing newline.

    	my @col = split /\t/, $_, -1;
    	# Identify its columns.

        for (my $i = 0; $i < @col; $i++) {
    	# For each of them:

    		if (exists $col{$i}) {
    			# If it is an expression column:

    			$col[$i] =~ s/⫷ex⫸/⫷ex:$col{$i}⫸/g;
    			# Insert the column's variety UID into each expression tag in it.
    		}
    	}

    	my $en = join '', @col;
    	# Identify a concatenation of its modified columns.

    	$en =~ s/⫷exp⫸.+?(?=⫷ex:)//g;
    	# Delete all deprecated (i.e. pre-normalized) expressions in it.

    	unless (exists $all{$en}) {
    	# If it is not a duplicate:

    		$all{$en} = '';
    		# Add it to the table of entries.

    		$en =~ s/⫷ex:([a-z]{3}-\d{3})⫸/\n$1\n/g;
    		# Convert all expression tags in it.

    		print $out $en, "\n";
    		# Output the converted line.
    	}
    }
};

1;