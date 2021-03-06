package PanLex::Serialize;
use strict;
use parent 'Exporter';
use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

our @EXPORT = qw(serialize);

use JSON::MaybeXS;
use File::Spec::Functions qw(catfile curdir rel2abs);
use List::Util qw(first);
use Scalar::Util qw(blessed);

use PanLex::Serialize::apostrophe;
use PanLex::Serialize::copydntag;
use PanLex::Serialize::csppmap;
use PanLex::Serialize::dcstag;
use PanLex::Serialize::dftag;
use PanLex::Serialize::dmtag;
use PanLex::Serialize::dpptag;
use PanLex::Serialize::exdftag;
use PanLex::Serialize::extag;
use PanLex::Serialize::mcsmap;
use PanLex::Serialize::mcstag;
use PanLex::Serialize::mdtag;
use PanLex::Serialize::mitag;
use PanLex::Serialize::mnsplit;
use PanLex::Serialize::mpptag;
use PanLex::Serialize::normalize;
use PanLex::Serialize::normalizedf;
use PanLex::Serialize::out_full_0;
use PanLex::Serialize::out_simple_0;
use PanLex::Serialize::out_simple_2;
use PanLex::Serialize::replace;
use PanLex::Serialize::spellcheck;
use PanLex::Serialize::wctag;

my @try_extensions = qw(txt csv tsv);

sub serialize {
    my ($basename, $version, $tools) = @_;

    print "\n";
    die "could not find PANLEX_TOOLDIR" unless -d $ENV{PANLEX_TOOLDIR};
    die "odd number of items in \@tools" unless @$tools % 2 == 0;

    my $log = { tools => $tools, basename => $basename, version => $version };

    # get the panlex-tools revision.
    my $pwd = rel2abs(curdir());
    chdir $ENV{PANLEX_TOOLDIR};
    my $rev = `git rev-parse HEAD`;
    chomp $rev;
    chdir $pwd;
    $log->{git_revision} = $rev;

    for (my $i = 0; $i < @$tools; $i += 2) {
        my ($tool, $args) = @{$tools}[$i, $i+1];

        my $input = first { -e $_ } map { "$basename-$version.$_" } @try_extensions;
        die "could not find file " . join(' or ', map { "$basename-$version.$_" } @try_extensions)
            unless defined $input;

        open my $in, '<', $input or die $!;

        $version = $tool =~ /^out/ ? 'final' : $version+1;

        my $output = "$basename-$version.txt";
        open my $out, '>', "$basename-$version.txt" or die $!;

        printf "%-13s %s => %s\n", $tool.':', $input, $output;

        die "tool arguments must be a hash or array ref"
            unless ref $args eq 'HASH' || ref $args eq 'ARRAY';

        # stringify any blessed arguments, so they will be processed correctly
        # and can be converted to JSON.
        foreach my $val (ref $args eq 'HASH' ? values %$args : @$args) {
            $val = ''.$val if defined blessed($val);
        }

        my $sub = $tool =~ s/-/_/gr;
        $sub = __PACKAGE__->can($sub);

        die "tool $tool not found" unless $sub;

        $sub->($in, $out, $args);

        close $in;
        close $out;

        last if $tool =~ /^out/;
    }

    $log->{time} = time();

    open my $fh, '>', 'log.json' or die $!;
    print $fh JSON->new->pretty->canonical->encode($log);
    close $fh;

    print "\n";
}

1;
