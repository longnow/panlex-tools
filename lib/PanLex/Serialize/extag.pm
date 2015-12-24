# Tags all expressions and all intra-column meaning changes in a tab-delimited 
# source file, disregarding any definitional parts.
# Arguments:
#   cols:     array of columns containing expressions.
#   syndelim: synonym delimiter (regex), or '' if none. default '‣'.
#   mndelim:  meaning delimiter (regex), or '' if none. default '⁋'.
#   extag:    expression tag. default '⫷ex⫸'.
#   mntag:    meaning tag. default '⫷mn⫸'.

package PanLex::Serialize::extag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw/extag/;

sub extag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@excol, $syndelim, $mndelim, $extag, $mntag, $tagged);
    
    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @excol    = @{$args->{cols}};
        $syndelim = $args->{syndelim} // '‣';
        $mndelim  = $args->{mndelim} // '⁋';
        $extag    = $args->{extag} // '⫷ex⫸';
        $mntag    = $args->{mntag} //  '⫷mn⫸';
    } else {
        ($syndelim, $mndelim, $extag, $mntag, @excol) = @$args;
        validate_cols(\@excol);
    }
    
    # For each line of the input file:
    while (<$in>) {
        chomp;
        # Delete its trailing newline.        

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        foreach my $i (@excol) {
        # For each expression column:
            
            die "column $i not present in line" unless defined $col[$i];

            $col[$i] =~ s/$syndelim/$extag/g if length $syndelim;
            # Convert each expression delimiter in it to an expression tag, if expression
            # delimiters exist.

            $col[$i] =~ s/$mndelim/$mntag$extag/g if length $mndelim;
            # Convert each meaning delimiter in it to a meaning tag and an expression tag,
            # if meaning delimiters exist.

            $col[$i] = "$extag$col[$i]" if length $col[$i] && $col[$i] !~ /^(?:$extag|$mntag)/;
            # Prefix an expression tag to the column, if not blank and not already
            # containing a leading expression or meaning tag.

            $col[$i] =~ s/$extag(?=$extag|$mntag|$)//g;
            # Delete all expression tags with blank contents.

            $col[$i] =~ s/$extag(?=⫷(?:ex|df)[⫸:])//g;
            # Delete additional expression tags with blank contents.

            $col[$i] =~ s/$mntag(?=$mntag|$)//g;
            # Delete all meaning tags with blank contents.
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }
}

1;