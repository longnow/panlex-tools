# Converts text to classifications and properties based on a mapping file.
# Arguments:
#   cols:   array of columns containing data to be mapped.
#   file:   name of the mapping file. default ''.
#   delim:  inter-classification/property delimiter in file. default '‣'.
#   log:    set to 1 to log unconvertible items to csppmap.log, 0 otherwise.
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
    my $type        = $args->{type} // 'd';
    my $file        = $args->{file} // '';
    my $delim       = $args->{delim} // '‣';
    my $log         = $args->{log} // 0;

    die "invalid type: $type" unless $type eq 'd' || $type eq 'm';

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

            my $result = ''; 

            if (exists $map{$col[$i]}) {
                my $val = $map{$col[$i]};

                $result .= cstag_item($val->{type} . 'cs', $_) for @{$val->{cs}};
                $result .= pptag_item($val->{type} . 'pp', $_) for @{$val->{pp}};
            } else {
                $notfound{$col[$i]} = '';
            }

            $col[$i] = $result;
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