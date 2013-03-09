# Splits multi-meaning lines of a tagged source file, eliminating any duplicate output lines.
# Arguments:
#	0: meaning-delimitation tag.
#	1: number (0-based) of the column that may contain multiple meanings.

package PanLex::Serialize::mnsplit;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

sub process {
    my ($in, $out, $mndelim, $mncol) = @_;
    my %line;
    
    while (<$in>) {
    # For each line of the input file:

    	chomp;
    	# Delete its trailing newline.

    	my @col = split /\t/, $_, -1;
    	# Identify its columns.

    	if ((index $col[$mncol], $mndelim) < 0) {
    	# If the potentially multimeaning column is one-meaning:

    		unless (exists $line{$_}) {
    		# If the line isn't a duplicate:

    			$line{$_} = '';
    			# Add it to the table of output lines.

    			print $out $_, "\n";
    			# Output it.
    		}
    	}

    	else {
    	# Otherwise, i.e. if the column is multimeaning:

    		foreach my $mn (split /$mndelim/, $col[$mncol]) {
    		# For each of its meaning segments:

    			my @line = @col;
    			# Identify its line's columns, with the multimeaning column unchanged.

    			$line[$mncol] = $mn;
    			# Replace the multimeaning column with the meaning segment.

    			my $ln = (join "\t", @line);
    			# Identify the meaning's line.

    			unless (exists $line{$ln}) {
    			# If it isn't a duplicate:

    				$line{$ln} = '';
    				# Add it to the table of output lines.

    				print $out $ln, "\n";
    				# Output it.
    			}
    		}
    	}
    }
}

1;