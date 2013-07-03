# Tags all expressions and all intra-column meaning changes in a tab-delimited 
# source file, disregarding any definitional parts.
# Arguments:
#   cols:     array of columns containing expressions.
#   syndelim: synonym delimiter (regex), or '' if none; default '‣'.
#   mndelim:  meaning delimiter (regex), or '' if none; default '⁋'.
#   extag:    expression tag; default '⫷ex⫸'.
#   mntag:    meaning tag; default '⫷mn⫸'.

package PanLex::Serialize::extag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variables, etc. except references.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

sub process { 
    my ($in, $out, $args) = @_;
    
    validate_cols($args->{cols});
    
    my @excol   = @{$args->{cols}};
    my $exdelim = defined $args->{exdelim} ? $args->{exdelim} : '‣';
    my $mndelim = defined $args->{mndelim} ? $args->{mndelim} : '⁋';
    my $extag   = defined $args->{extag} ? $args->{extag} : '⫷ex⫸';
    my $mntag   = defined $args->{mntag} ? $args->{mntag} :  '⫷mn⫸';
    
    # For each line of the input file:
    while (<$in>) {
        chomp;
        # Delete its trailing newline.        

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@excol) {
        # For each expression column:
            
            die "column $i not present in line" unless defined $col[$i];

            $col[$i] =~ s/$exdelim/$extag/og if length $exdelim;
            # Convert each expression delimiter in it to an expression tag, if expression
            # delimiters exist.

            $col[$i] =~ s/$mndelim/$mntag$extag/og if length $mndelim;
            # Convert each meaning delimiter in it to a meaning tag and an expression tag,
            # if meaning delimiters exist.

            $col[$i] = "$extag$col[$i]" if length $col[$i] && $col[$i] !~ /^(?:$extag|$mntag)/o;
            # Prefix an expression tag to the column, if not blank and not already
            # containing a leading expression or meaning tag.

            $col[$i] =~ s/$extag(?=$extag|$mntag|$)//og;
            # Delete all expression tags with blank contents.

            $col[$i] =~ s/$mntag(?=$mntag|$)//og;
            # Delete all meaning tags with blank contents.
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }
}

1;