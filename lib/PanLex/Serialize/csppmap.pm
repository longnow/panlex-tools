# Converts text to classifications and properties based on a mapping file.
# Arguments:
#   cols:     array of columns containing data to be mapped.
#   file:     name of the mapping file. default 'csppmap.txt'.
#   delim:    inter-classification/property delimiter in file. default '‣'.
#   default:  meaning or denotation attribute expression to use for unconviertible
#               items, or '' if none. default 'd⁋art-300⁋HasProperty', where 'd'
#               specifies a denotation property (use 'm' for meaning), 'art-300'
#               is the expression's UID, and 'HasProperty' is its text.
#   log:      set to 1 to log unconvertible items to csppmap.log, 0 otherwise.
#               default: 0.

package PanLex::Serialize::csppmap;
use strict;
use warnings 'FATAL', 'all';
use utf8;
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
    my $delim       = $args->{delim} // '‣';
    my $default     = $args->{default} // 'd⁋art-300⁋HasProperty';
    my $log         = $args->{log} // 0;

    my $default_type;

    if ($default ne '') {
        die "default parameter must take the form 'd⁋UID⁋text' or 'm⁋UID⁋text' (delimiter is arbitrary)"
            unless $default =~ /^([dm])(.)/;

        $default_type = $1;
        $default = substr($default, 2) . $2;
    }

    $file = catfile($ENV{PANLEX_TOOLDIR}, 'serialize', 'data', $file)
        unless -e $file;

    my %map;

    open my $mapin, '<:encoding(utf8)', $file or die $!;

    while (<$mapin>) {
        chomp;

        my @col = split /\t/, $_, -1;

        die "map file line does not have four columns" unless @col == 4;
        die "invalid type column: $col[1] (must be 'd' or 'm')" unless $col[1] eq 'd' || $col[1] eq 'm';

        $map{$col[0]} = { 
            type => $col[1], 
            cs => [ split /$delim/, $col[2] ], 
            pp => [ split /$delim/, $col[3] ],
        };
    }

    close $mapin;

    my %notfound;

    while (<$in>) {
        chomp;

        my @col = split /\t/, $_, -1;

        foreach my $i (@csppmapcol) {
            next unless length $col[$i];

            my $newval = ''; 

            if (exists $map{$col[$i]}) {
                my $val = $map{$col[$i]};

                $newval .= cstag_item($val->{type} . 'cs', $_) for @{$val->{cs}};
                $newval .= pptag_item($val->{type} . 'pp', $_) for @{$val->{pp}};
            } else {
                $notfound{$col[$i]} = '';

                $newval = pptag_item($default_type . 'pp', $default . $col[$i]) if $default_type;
            }

            $col[$i] = $newval;
        }

        print $out join("\t", @col), "\n";
    }

    if ($log) {
        open my $log_fh, '>:encoding(utf8)', 'csppmap.log' or die $!;
        print $log_fh join("\n", sort keys %notfound), "\n";
        close $log_fh;
    }

}

1;