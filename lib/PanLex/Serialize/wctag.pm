#'wctag'        => { col => 1 },
# Converts and tags word classifications in a tab-delimited source file.
# Arguments:
#   col:   column containing word classifications.
#   wctag: word-classification tag. default '⫷wc⫸'.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.

package PanLex::Serialize::wctag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw/wctag/;

use PanLex::Validation;
use File::Spec::Functions;
use File::Basename;

sub wctag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($wccol, $wctag, $mdtag);
    
    if (ref $args eq 'HASH') {
        $wccol    = $args->{col};
        $wctag    = $args->{wctag} // '⫷wc⫸';
        $mdtag    = $args->{mdtag} // '⫷md:gram⫸';      
    } else {
        ($wccol, $wctag, $mdtag) = @$args;
    }

    validate_col($wccol);
    
    my $wctxt = -e 'wc.txt' ? 'wc.txt' : catfile(dirname(__FILE__), '..', 'data', 'wc.txt');
    open my $wc, '<:utf8', $wctxt or die $!;
    # Open the wc file for reading.

    my %wc;

    while (<$wc>) {
    # For each line of the wc file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        $wc{$col[0]} = $col[1];
        # Add it to the table of wc conversions.
    }
    
    close $wc;

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $wccol not present in line" unless defined $col[$wccol];

        if (exists $wc{$col[$wccol]}) {
        # If the content of the column containing word classifications is a convertible one:

            my @wcmd = split /:/, $wc{$col[$wccol]};
            # Identify the wc and the md values of its conversion.

            if (@wcmd == 1) {
            # If there is no md value:

                $col[$wccol] = "$wctag$wcmd[0]";
                # Convert the wc to a tagged wc.
            }

            elsif (@wcmd == 2) {
            # Otherwise, if there is an md value:

                if (length $wcmd[0]) {
                # If there is a wc value:

                    $col[$wccol] = "$wctag$wcmd[0]$mdtag$wcmd[1]";
                    # Convert the wc to a wc and an md, each tagged.
                }

                else {
                # Otherwise, i.e. if there is no wc value:

                    $col[$wccol] = "$mdtag$wcmd[1]";
                    # Convert the wc to a tagged md.
                }
            }
        }

        elsif (length $col[$wccol]) {
        # Otherwise, if the content of the column containing word classifications is
        # not blank:

            $col[$wccol] = "$mdtag$col[$wccol]";
            # Convert the content to a tagged md.
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;