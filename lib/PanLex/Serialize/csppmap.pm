# Converts text to classifications and properties based on a mapping file.
# Arguments:
#   cols:       array of columns containing data to be mapped.
#   file:       name of the mapping file. default 'csppmap.txt'.
#   type:       type of the mapping file ('d' for denotation, 'm' for meaning).
#                   default 'd'.
#   delim:      inter-classification/property delimiter in file and columns.
#                   default '‣'.
#   default:    meaning or denotation attribute expression to use for unconvertible
#                 items, or 'pass' if they should be left unchanged, or '' if they 
#                 should be deleted. default 'art-303⁋LinguisticProperty', where 
#                 'art-303' is the expression's UID, and 'LinguisticProperty' is 
#                 its text.
#   mapdefault: attribute expression to use when the mapping file property column
#                 is '*'. default 'art-303⁋LinguisticProperty', where 'art-303' is 
#                 the expression's UID, and 'LinguisticProperty' is its text.
#   log:        set to 1 to log unconvertible items to csppmap.log, 0 otherwise.
#                 default: 0.

package PanLex::Serialize::csppmap;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IO => ':raw :encoding(utf8)';
use parent 'Exporter';
use File::Spec::Functions;
use PanLex::Validation;
use PanLex::Serialize::cstag 'cstag_item';
use PanLex::Serialize::pptag 'pptag_item';

our @EXPORT = qw/csppmap/;

sub csppmap {
    my ($in, $out, $args) = @_;

    validate_cols($args->{cols});

    my @csppmapcol  = @{$args->{cols}};
    my $file        = $args->{file} // 'csppmap.txt';
    my $type        = $args->{type} // 'd';
    my $delim       = $args->{delim} // '‣';
    my $default     = $args->{default} // 'art-303⁋LinguisticProperty';
    my $mapdefault   = $args->{mapdefault} // 'art-303⁋LinguisticProperty';
    my $log         = $args->{log} // 0;

    die "type paremeter must be 'd' or 'm'" unless $type =~ /^[dm]$/;

    if ($default ne '') {
        die "default parameter must take the form 'UID⁋text' (delimiter is arbitrary)"
            unless $default =~ /^[a-z]{3}-\d{3}(.).+$/ || $default eq 'pass';
        $default .= $1 if $default ne 'pass';
    }

    die "mapdefault parameter must take the form 'UID⁋text' (delimiter is arbitrary)"
        unless $mapdefault =~ /^[a-z]{3}-\d{3}(.).+$/;
    $mapdefault .= $1;

    $file = catfile($ENV{PANLEX_TOOLDIR}, 'serialize', 'data', $file)
        unless -e $file;

    my %map;

    open my $mapin, '<', $file or die $!;

    while (<$mapin>) {
        chomp;

        my @col = split /\t/, $_, -1;

        die "map file line does not have three columns" unless @col == 3;
        $col[2] = $mapdefault . $col[0] if $col[2] eq '*';

        $map{$col[0]} = { 
            cs => [ split /$delim/, $col[1] ], 
            pp => [ split /$delim/, $col[2] ],
        };
    }

    close $mapin;

    my %notfound;

    while (<$in>) {
        chomp;

        my @col = split /\t/, $_, -1;

        foreach my $i (@csppmapcol) {
            die "column $i not present in line" unless defined $col[$i];

            next unless length $col[$i];

            my $tagged = ''; 

            foreach my $el (split $delim, $col[$i]) {
                if (exists $map{$el}) {
                    my $mapped = $map{$el};

                    $tagged .= cstag_item("${type}cs", $_) for @{$mapped->{cs}};
                    $tagged .= pptag_item("${type}pp", $_) for @{$mapped->{pp}};
                } else {
                    $notfound{$el} = '';

                    if ($default eq 'pass') {
                        $tagged .= $delim if length $tagged;
                        $tagged .= $el;
                    } elsif ($default ne '') {
                        $tagged .= pptag_item("${type}pp", $default . $el);
                    }
                }
            }

            $col[$i] = $tagged;
        }

        print $out join("\t", @col), "\n";
    }

    if ($log) {
        open my $log_fh, '>', 'csppmap.log' or die $!;
        print $log_fh join("\n", sort keys %notfound), "\n";
        close $log_fh;
    }

}

1;