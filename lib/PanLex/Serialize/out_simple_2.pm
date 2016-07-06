# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#   uids:   two-element array containing variety UIDs of columns 0 and 1.

package PanLex::Serialize::out_simple_2;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;

our @EXPORT = qw(out_simple_2);

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

    print $out ":\n2\n";
    # Output the file header.

    my %seen;

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        s/\t//g;
        # Delete all tabs.

        s/⫷(?:exp|rm)⫸[^⫷]*//g;
        # Delete all pre-normalized expressions and all tags that are marked as to be removed.

        unless (exists $seen{$_}) {
        # If it is not a duplicate:

            $seen{$_} = '';
            # Add it to the table of entries.

            s/⫷ex⫸/\n  dn\n    $uids[0]\n    /;
            s/⫷ex⫸/\n  dn\n    $uids[1]\n    /;
            # Convert all expression tags.

            print $out "\nmn$_\n";
            # Output the converted line.
        }
    }    
}

1;