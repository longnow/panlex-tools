# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#    0: variety UID of column 0.
#    1: variety UID of column 1.

package PanLex::Serialize::out_simple_2;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

$PanLex::Serialize::out_simple_2::final = 1;

sub process {
    my ($in, $out, $lv1, $lv2) = @_;
    
    validate_uid($lv1);
    validate_uid($lv2);

    print $out ".\n2\n$lv1\n$lv2\n";
    # Output the file header.

    my %all;

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        s/⫷exp⫸[^⫷]+//g;
        # Delete all unnormalized expressions.

        unless (exists $all{$_}) {
        # If it is not a duplicate:

            $all{$_} = '';
            # Add it to the table of entries.

            s/\t?⫷ex⫸/\n/g;
            # Convert all expression tags and the inter-column tab.

            print $out $_, "\n";
            # Output the converted line.
        }
    }    
}

1;