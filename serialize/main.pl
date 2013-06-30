#!/usr/bin/env perl
# Converts a tab-delimited source file for uploading to PanLex.
use strict;
use utf8;
use JSON;

# The basename of the source file.
my $BASENAME = 'aaa-bbb-Author';

# The initial version to use.
my $VERSION = 0;

# The panlex-tools directory containing the serialize scripts. If unset here,
# will look next in env var PANLEX_TOOLDIR, otherwise use the current directory.
my $PANLEX_TOOLDIR;

my @TOOLS = (
    
#'apostrophe'   => [ '1:gyd-000', '3:nny-000', '5:eng-000' ],
# Converts a tab-delimited source file's apostrophes.
# Arguments:
#    0+: specifications (column index and variety UID, colon-delimited) of columns
#        possibly requiring apostrophe normalization.

#'extag'        => [ '‣', '⁋', '⫷ex⫸', '⫷mn⫸', 0, 1 ],
# Tags all expressions and all intra-column meaning changes in a tab-delimited source file,
# disregarding any definitional parts.
# Arguments:
#    0: synonym delimiter (regular expression), or blank if none.
#    1: meaning delimiter (regular expression), or blank if none.
#    2: expression tag.
#    3: meaning tag.
#    4+: columns containing expressions.

#'exdftag'      => [ '⫷ex⫸', '[^⫷]', '[^⫷ ]', '(?:\([^()]+\)|（[^（）]+）)', '⫷df⫸', 25, 3, '[][/,;?!~]', '⫷[^⫷⫸]+⫸', 2 ],
# Splits definitional expressions into reduced expressions and definitions in a source file with
# already-tagged expressions and tags the added definitions.
# Arguments:
#    0: expression tag in file.
#    1: regular expression matching any post-tag character.
#    2: regular expression matching any post-tag character that is not a space.
#    3: regular expression matching a definitional part of an expression.
#    4: definition tag to be used on definitions.
#    5: maximum character count permitted in an expression, or blank if none.
#    6: maximum word count permitted in an expression, or blank if none.
#    7: regular expression matching any substring forcing an expression to be
#        reclassified as a definition, or blank if none.
#    8: regular expression matching a preposed annotation not to be counted,
#        or blank if none.
#    9+: columns containing expressions that may contain definitional parts.

#'dftag'        => [ '⫷df⫸', 1, 2 ],
# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#    0: definition tag.
#    1+: columns containing definitions.

#'mitag'        => [ 2, '⫷mi⫸' ],
# Tags meaning identifiers.
# Arguments:
#    0: column that contains meaning identifiers.
#    1: meaning-identifier tag.

#'wcretag'      => [ '⫷wc:', '⫸', '⫷wc⫸', '⫷md:gram⫸', 1, 2 ],
# Retags word classifications in a tab-delimited source file.
# Arguments:
#    0: input file's wc tag before its content.
#    1: input file's wc tag after its content.
#    2: output file's word-classification tag.
#    3: metadatum tag.
#    4+: columns containing word classifications.

#'wctag'        => [ 1, '⫷wc⫸', '⫷md:gram⫸' ],
# Converts and tags word classifications in a tab-delimited source file.
# Arguments:
#    0: column containing word classifications.
#    1: word-classification tag.
#    2: metadatum tag.

#'mdtag'        => [ 2, '⫷md:gram⫸' ],
# Tags metadata in a tab-delimited source file.
# Arguments:
#    0: column containing metadata.
#    1: metadatum tag.

#'dmtag'        => [ '⫷dm⫸', '‣', 2, 3 ],
# Tags domain expressions in a tab-delimited source file.
# Arguments:
#    0: domain-expression tag.
#    1: inter-expression delimiter, or blank if none.
#    2+: columns containing domain expressions.

#'mnsplit'      => [ '⫷mn⫸', 2 ],
# Splits multi-meaning lines of a tagged source file, eliminating any duplicate output lines.
# Arguments:
#    0: meaning-delimitation tag.
#    1: number (0-based) of the column that may contain multiple meanings.

#'wcshift'      => [ 2, '⫷wc:', '⫸', '⫷wc⫸', '⫷ex⫸', '[^⫷]' ],
# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file.
# Arguments:
#    0: column containing prepended word class specifications.
#    1: start of word-class specification.
#    2: end of word-class specification.
#    3: word-classification tag.
#    4: expression tag.
#    5: regular expression matching any post-tag character.

#'normalize'    => [ '⫷[a-z:]+⫸', '⫷ex⫸', 0, 50, 10, 'eng-000', '⫷exp⫸', '⫷df⫸', ', ' ],
# Normalizes expressions in a tagged source file.
# Arguments:
#    0: tag specification (regular expression).
#    1: expression tag.
#    2: column containing expressions to be normalized.
#    3: minimum score (0 or more) a proposed expression must have in order to be accepted
#        outright as an expression. Every proposed expression with a lower (or no) score is
#        to be replaced with the highest-scoring expression sharing its language variety and
#        degradation, if any such expression has a higher score than it.
#    4: minimum score a proposed expression that is not accepted outright as an expression,
#        or its replacement, must have in order to be accepted as an expression.
#    5: variety UID of expressions to be normalized.
#    6: tag of pre-normalized expression.
#    7: if proposed expressions not accepted as expressions and not having replacements accepted
#        as expressions are to be converted to definitions, definition tag, or blank if they
#        are to be converted to pre-normalized expressions.
#    8: regular expression matching the synonym delimiter if each proposed expression containing
#        such a delimiter is to be treated as a list of synonymous proposed expressions and
#        they are to be normalized if and only if all expressions in the list are
#        normalizable, or blank if not.

#'out-simple-0'   => [ '0:rus-000', '1:eng-000' ],
# Converts a normally tagged source file to a simple-text varilingual source file,
# eliminating duplicates.
# Arguments:
#    0+: specifications (column index and variety UID, colon-delimited) of columns
#        containing expressions.

#'out-simple-2' => [ 'rus-000', 'eng-000' ],
# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#    0: variety UID of column 0.
#    1: variety UID of column 1.

#'out-full-0'   => [ '', 2, 2, '0:rus-000', '1:eng-000' ],
# Converts a standard tagged source file to a full-text varilingual source file.
# Arguments:
#    0: word classification to annotate all expressions as that have no tagged wc,
#        or blank if none.
#    1: minimum count (2 or more) of definitions and expressions per entry.
#    2: minimum count (1 or more) of expressions per entry.
#    3+: specifications (column index and variety UID, colon-delimited) of columns
#        containing tags (ex, df, dm) requiring variety specifications.

#'out-full-2'   => [ '', 2, 1, '0:rus-259', '1:eng-000' ],
# Converts a standard tagged source file to a full-text bilingual source file, eliminating duplicates.
# Arguments:
#    0: word classification to annotate all expressions as that have no tagged wc, or blank if none.
#    1: minimum count (2 or more) of definitions and expressions per entry.
#    2: minimum count (1 or more) of expressions per entry.
#    3: column index and variety UID, colon-delimited, of source expression column
#    4: column index and variety UID, colon-delimited, of target expression column
#    5*: specifications (column index and variety UID, colon-delimited) of other columns
#        containing tags (df, dm) requiring variety specifications.

);

### DO NOT MODIFY BELOW THIS LINE ###

use File::Spec::Functions qw/catfile curdir rel2abs/;
binmode STDOUT, ':utf8';

print "\n";
die "odd number of items in \@TOOLS" unless @TOOLS % 2 == 0;

foreach my $dir (grep { $_ && -d $_ } ($PANLEX_TOOLDIR, $ENV{PANLEX_TOOLDIR})) {
    push @INC, catfile($dir, 'serialize', 'sub');    
    push @INC, catfile($dir, 'lib');    
}

$PANLEX_TOOLDIR ||= $ENV{PANLEX_TOOLDIR};

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
    my ($tool,$args) = @TOOLS[$i, $i+1];

    require $tool . '.pl';
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
    $pkg->can('process')->($in, $out, @$args);

    close $in;
    close $out;
}

$log->{time} = time();

open my $fh, '>:utf8', 'log.json' or die $!;
print $fh JSON->new->pretty(1)->canonical(1)->encode($log);
close $fh;

print "\n";