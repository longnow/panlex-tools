# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#   uids:   two-element array containing variety UIDs of columns 0 and 1.

package PanLex::Serialize::out_simple_2;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;

our $final = 1;
# Declare that this script produces a final source file.

sub process {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my @uids;
    
    if (ref $args eq 'HASH') {
        validate_uids($args->{uids});
        @uids = @{$args->{uids}};
    } else {
        @uids = @$args;
        validate_uids(\@uids);
    }

    die "you must specify exactly two UIDs" if @uids != 2;

    print $out ".\n2\n$uids[0]\n$uids[1]\n";
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