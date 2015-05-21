# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#   uids:   two-element array containing variety UIDs of columns 0 and 1.

package PanLex::Serialize::out_simple_2;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';

use vars qw/@EXPORT/;
@EXPORT = qw/out_simple_2/;

use PanLex::Validation;

sub out_simple_2 {
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

        s/⫷rm⫸[^⫷]+//g;
        # Delete all tags that are marked as to be removed.

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