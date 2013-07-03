# Retags word classifications in a tab-delimited source file.
# Arguments:
#    0: input file's wc tag before its content.
#    1: input file's wc tag after its content.
#    2: output file's word-classification tag.
#    3: metadatum tag.
#    4+: columns containing word classifications.

package PanLex::Serialize::wcretag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use PanLex::Validation;
use File::Spec::Functions;
use File::Basename;

sub process {
    my ($in, $out, $pretag, $posttag, $wctag, $mdtag, @wccol) = @_;
    
    validate_col($_) for @wccol;

    open my $wc, '<:utf8', catfile(dirname(__FILE__), '..', 'data', 'wc.txt') or die $!;
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

        foreach my $i (@wccol) {
        # For each column containing word classifications:

            while ($col[$i] =~ /$pretag(.+?)$posttag/) {
            # As long as any remains unretagged:

                if (exists $wc{$1}) {
                # If the first one's content is convertible:

                    my @wcmd = split /:/, $wc{$1};
                    # Identify the wc and the md values of its conversion.

                    if (@wcmd == 1) {
                    # If there is no md value:

                        $col[$i] =~ s/$pretag.+?$posttag/$wctag$wcmd[0]/;
                        # Retag the wc.
                    }

                    else {
                    # Otherwise, i.e. if there is an md value:

                        if (length $wcmd[0]) {
                        # If there is a wc value:

                            $col[$i] =~ s/$pretag.+?$posttag/$wctag$wcmd[0]$mdtag$wcmd[1]/;
                            # Retag the wc.
                        }

                        else {
                        # Otherwise, i.e. if there is no wc value:

                            $col[$i] =~ s/$pretag.+?$posttag/$mdtag$wcmd[1]/;
                            # Retag the wc.
                        }
                    }
                }

                else {
                # Otherwise, i.e. if the first one's content is not convertible:

                    my $md = $1;
                    # Identify it.

                    $col[$i] =~ s/$pretag.+?$posttag/$mdtag$md/;
                    # Retag the wc.
                }
            }
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;