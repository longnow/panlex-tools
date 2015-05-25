#'wcretag'      => { cols => [1, 2] },
# Retags word classifications in a tab-delimited source file.
# Arguments:
#   cols:     array of columns containing word classifications.
#   pretag:   input file's wc tag before its content. default '⫷wc:'.
#   posttag:  input file's wc tag after its content. default '⫸'.
#   wctag:    output file's word-classification tag. default '⫷wc⫸'
#   mdtag:    metadatum tag. default '⫷md:gram⫸'.

package PanLex::Serialize::wcretag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::Util;

our @EXPORT = qw/wcretag/;

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

    my $wc = load_wc();

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

                my $replacement;

                if (exists $wc->{$1}) {
                # If the first one's content is convertible:

                    my @wcmd = @{$wc->{$1}};
                    # Identify the wc and the md values of its conversion.

                    $replacement .= "$wctag$wcmd[0]" if length $wcmd[0];
                    # Identify the tagged wc value, if any.

                    $replacement .= "$mdtag$wcmd[1]" if @wcmd == 2;
                    # Identify the tagged md value, if any.

                }

                else {
                # Otherwise, i.e. if the first one's content is not convertible:

                    $replacement = "$mdtag$1";
                    # Identify the tagged md value.

                }

                $col[$i] =~ s/$pretag.+?$posttag/$replacement/;
            }
        }

        print $out join("\t", @col), "\n";
        # Output the line.
    }    
}

1;