use strict;
use JSON;
use File::Spec::Functions qw/catfile curdir rel2abs/;
use PanLex::Validation;
binmode STDOUT, ':utf8';

sub run {
    my ($PANLEX_TOOLDIR, $BASENAME, $VERSION, $TOOLS) = @_;
    my @TOOLS = @$TOOLS;

    print "\n";
    die "odd number of items in \@TOOLS" unless @TOOLS % 2 == 0;

    my $log = { tools => \@TOOLS };

    if (-d $PANLEX_TOOLDIR) {    
        # get the panlex-tools revision.
        my $pwd = rel2abs(curdir());
        chdir $PANLEX_TOOLDIR;
        my $rev = `git rev-parse HEAD`;
        chomp $rev;
        chdir $pwd;
        $log->{git_revision} = $rev;
    }

    for (my $i = 0; $i < @TOOLS; $i += 2) {
        my ($tool, $args) = @TOOLS[$i, $i+1];

        validate_hash($args);

        my $tool_path = catfile('sub', $tool . '.pl');
        require $tool_path;
        my $pkg = 'PanLex::Serialize::' . $tool;
        $pkg =~ tr/-/_/;

        my $input = "$BASENAME-$VERSION.txt";
        die "could not find file $input" unless -e $input;
        open my $in, '<:utf8', $input or die $!;

        {   
            no strict 'refs';
            $VERSION = ${$pkg.'::final'} ? 'final' : $VERSION+1;
        }

        my $output = "$BASENAME-$VERSION.txt";
        open my $out, '>:utf8', "$BASENAME-$VERSION.txt" or die $!;

        printf "%-13s %s => %s\n", $tool.':', $input, $output;

        $pkg->can('process')->($in, $out, $args);      

        close $in;
        close $out;
    }

    $log->{time} = time();

    open my $fh, '>:utf8', 'log.json' or die $!;
    print $fh JSON->new->pretty(1)->canonical(1)->encode($log);
    close $fh;

    print "\n";
}

1;