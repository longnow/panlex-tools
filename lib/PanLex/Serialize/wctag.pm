#'wctag'        => { col => 1 },
# Converts and tags word classifications in a tab-delimited source file.
# Arguments:
#   col:   column containing word classifications.
#   wctag: word-classification tag. default '⫷wc⫸'.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.
#   log:   set to 1 to log unconvertible word classes to wc.log, 0 otherwise.
#            default: 0.

package PanLex::Serialize::wctag;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use open IO => ':raw :encoding(utf8)';
use parent 'Exporter';
use PanLex::Validation;
use PanLex::Serialize::Util;

our @EXPORT = qw/wctag/;

sub wctag {
    my $in = shift;
    my $out = shift;
    my $args = ref $_[0] ? $_[0] : \@_;
    
    my ($wccol, $wctag, $mdtag, $log);
    
    if (ref $args eq 'HASH') {
        $wccol  = $args->{col};
        $wctag  = $args->{wctag} // '⫷wc⫸';
        $mdtag  = $args->{mdtag} // '⫷md:gram⫸';
        $log    = $args->{log} // 0; 
    } else {
        ($wccol, $wctag, $mdtag) = @$args;
        $log = 0;
    }

    validate_col($wccol);
    
    my $wc = load_wc();

    my %notfound;

    while (<$in>) {
    # For each line of the input file:

        chomp;
        # Delete its trailing newline.

        my @col = split /\t/, $_, -1;
        # Identify its columns.

        die "column $wccol not present in line" unless defined $col[$wccol];

        my $replacement = '';

        if (exists $wc->{$col[$wccol]}) {
        # If the content of the column containing word classifications is a convertible one:

            my @wcmd = @{$wc->{$col[$wccol]}};
            # Identify the wc and the md values of its conversion.

            $replacement .= "$wctag$wcmd[0]" if length $wcmd[0];
            # Identify the tagged wc value, if any.

            $replacement .= "$mdtag$wcmd[1]" if @wcmd == 2;
            # Identify the tagged md value, if any.

        }

        elsif (length $col[$wccol]) {
        # Otherwise, if the content of the column containing word classifications is
        # not blank:

            $replacement = "$mdtag$col[$wccol]";
            # Convert the content to a tagged md.

            $notfound{$col[$wccol]} = '';
            # Mark the word class as not found.
        }

        $col[$wccol] = $replacement;

        print $out join("\t", @col), "\n";
        # Output the line.
    }

    if ($log) {
        open my $log_fh, '>', 'wc.log' or die $!;
        print $log_fh join("\n", sort keys %notfound), "\n";
        close $log_fh;
    }
}

1;