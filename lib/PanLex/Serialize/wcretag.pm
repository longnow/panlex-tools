#'wcretag'      => { cols => [1, 2] },
# Retags word classifications in a tab-delimited source file.
# Arguments:
#   cols:     array of columns containing word classifications.
#   pretag:   input file's wc tag before its content. default '⫷wc:'.
#   posttag:  input file's wc tag after its content. default '⫸'.
#   wctag:    output file's word-classification tag. default '⫷wc⫸'
#   mdtag:    metadatum tag. default '⫷md:gram⫸'.

package PanLex::Serialize::wcretag;

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw/wcretag/;

use PanLex::Validation;
use File::Spec::Functions;
use File::Basename;

sub wcretag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;

    my (@wccol, $pretag, $posttag, $wctag, $mdtag);
    
    if (ref $args eq 'HASH') {
        validate_cols($args->{cols});

        @wccol    = @{$args->{cols}};
        $pretag   = $args->{pretag} // '⫷wc:';
        $posttag  = $args->{posttag} // '⫸';
        $wctag    = $args->{wctag} // '⫷wc⫸';
        $mdtag    = $args->{mdtag} // '⫷md:gram⫸';      
    } else {
        ($pretag, $posttag, $wctag, $mdtag, @wccol) = @$args;
        validate_cols(\@wccol);
    }

    my $wctxt = -e 'wc.txt' ? 'wc.txt' : catfile($ENV{PANLEX_TOOLDIR}, 'serialize', 'data', 'wc.txt');
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

        foreach my $i (@wccol) {
        # For each column containing word classifications:

            die "column $i not present in line" unless defined $col[$i];

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