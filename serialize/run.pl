use strict;
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

use JSON;
use File::Spec::Functions qw/catfile curdir rel2abs/;
use Scalar::Util 'blessed';
use PanLex::Serialize;

sub run {
    my ($PANLEX_TOOLDIR, $BASENAME, $VERSION, $TOOLS) = @_;
    my @TOOLS = @$TOOLS;

    print "\n";
    die "could not find PANLEX_TOOLDIR" unless -d $PANLEX_TOOLDIR;
    die "odd number of items in \@TOOLS" unless @TOOLS % 2 == 0;

    my $log = { tools => \@TOOLS, basename => $BASENAME, version => $VERSION };

    # get the panlex-tools revision.
    my $pwd = rel2abs(curdir());
    chdir $PANLEX_TOOLDIR;
    my $rev = `git rev-parse HEAD`;
    chomp $rev;
    chdir $pwd;
    $log->{git_revision} = $rev;

    for (my $i = 0; $i < @TOOLS; $i += 2) {
        my ($tool, $args) = @TOOLS[$i, $i+1];

        my $input = "$BASENAME-$VERSION.txt";
        die "could not find file $input" unless -e $input;
        open my $in, '<:encoding(utf8)', $input or die $!;

        $VERSION = $tool =~ /^out/ ? 'final' : $VERSION+1;

        my $output = "$BASENAME-$VERSION.txt";
        open my $out, '>:encoding(utf8)', "$BASENAME-$VERSION.txt" or die $!;

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
    }

    $log->{time} = time();

    open my $fh, '>:encoding(utf8)', 'log.json' or die $!;
    print $fh JSON->new->pretty->canonical->encode($log);
    close $fh;

    print "\n";
}

1;