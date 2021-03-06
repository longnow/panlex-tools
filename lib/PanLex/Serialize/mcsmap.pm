# Converts text to meaning classifications based on a mapping file.
# Arguments:
#   cols:       array of columns containing data to be mapped.
#   file:       name of the mapping file. default 'mcsmap.txt'.
#   intradelim: intra-classification delimiter in file and columns. default ':'.
#                   must be a single character.
#   interdelim: inter-classification delimiter in columns. default '‣'.
#                   must be a single character.
#   log:        set to 1 to log unconvertible items to mcsmap.log, 0 otherwise.
#                 default 1.

package PanLex::Serialize::mcsmap;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
use parent 'Exporter';
use File::Spec::Functions;
use PanLex::Validation;
use PanLex::Serialize::cstag 'cstag_item';

our @EXPORT = qw(mcsmap);

sub mcsmap {
    my ($in, $out, $args) = @_;

    validate_cols($args->{cols});

    my @mcsmapcol   = @{$args->{cols}};
    my $file        = $args->{file} // 'mcsmap.txt';
    my $intradelim  = $args->{intradelim} // ':';
    my $interdelim  = $args->{interdelim} // '‣';
    my $log         = $args->{log} // 1;

    die "intradelim must be one character long" if length $intradelim != 1;
    die "interdelim must be one character long" if length $interdelim != 1;

    $file = catfile($ENV{PANLEX_TOOLDIR}, 'serialize', 'data', $file)
        unless -e $file;

    my %map;

    open my $mapin, '<', $file or die $!;

    while (<$mapin>) {
        chomp;

        my @col = split /\t/, $_, -1;

        die "map file line does not have two columns" unless @col == 2;

        die "map file column is too short: $col[1]" unless length $col[1] > 8;

        $map{$col[0]} = [ substr($col[1], 0, 7), substr($col[1], 8) ];
    }

    close $mapin;

    my %notfound;

    while (<$in>) {
        chomp;

        my @col = split /\t/, $_, -1;

        foreach my $i (@mcsmapcol) {
            die "column $i not present in line" unless defined $col[$i];

            next unless length $col[$i];

            my $tagged = '';

            foreach my $el (split $interdelim, $col[$i]) {
                my ($unmapped, $rest) = split /$intradelim/, $el, 2;

                if (exists $map{$unmapped}) {
                    $tagged .= cstag_item('mcs', join($intradelim, @{$map{$unmapped}}, $rest));
                } else {
                    $notfound{$unmapped} = '';
                }
            }

            $col[$i] = $tagged;
        }

        print $out join("\t", @col), "\n";
    }

    if ($log) {
        open my $log_fh, '>', 'mcsmap.log' or die $!;
        print $log_fh join("\n", sort keys %notfound), "\n";
        close $log_fh;
    }

}

1;
