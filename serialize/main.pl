#!/usr/bin/env perl
# Converts a tab-delimited source file for uploading to PanLex.
use strict;
use File::Spec::Functions;
use Cwd;

# The basename of the source file.
my $BASENAME = 'aaa-bbb-Author';

# The initial version to use.
my $VERSION = 0;

# The directory containing serialize scripts. If unset here, will look next in 
# env var PANLEX_TOOLDIR, otherwise use the current directory.
my $SERIALIZEDIR;

# The path to the perl executable. If unset here, will look next in env var
# PANLEX_PERL, otherwise use the system default.
my $PERL;

# Perl commandline options. If unset here, will look next in env var
# PANLEX_PERLOPT, otherwise use the default of '-C63 -w'. 
my $PERLOPT;

my @TOOLS = (
    
#'apostrophe.pl'     => [ '1:gyd-000', '3:nny-000', '5:eng-000' ],
# Converts a tab-delimited source file's apostrophes.
# Arguments:
#	0+: specifications (column index and variety UID, colon-delimited) of columns
#		possibly requiring apostrophe normalization.

#'extag.pl'          => [ '‣', '⁋', '⫷ex⫸', '⫷mn⫸', 0, 1 ],
# Tags all expressions and all intra-column meaning changes in a tab-delimited source file,
# disregarding any definitional parts.
# Arguments:
#	0: synonym delimiter (regular expression), or blank if none.
#	1: meaning delimiter (regular expression), or blank if none.
#	2: expression tag.
#	3: meaning tag.
#	4+: columns containing expressions.

#'exdftag.pl'        => [ '⫷ex⫸', '[^⫷]', '[^⫷ ]', '(?:\([^()]+\)|（[^（）]+）)', '⫷df⫸', 25, 3, '[][/,;?!~]', '«[^«»]+»', 2 ],
# Splits definitional expressions into reduced expressions and definitions in a source file with
# already-tagged expressions and tags the added definitions.
# Arguments:
#	0: expression tag in file.
#	1: regular expression matching any post-tag character.
#	2: regular expression matching any post-tag character that is not a space.
#	3: regular expression matching a definitional part of an expression.
#	4: definition tag to be used on definitions.
#	5: maximum character count permitted in an expression, or blank if none.
#	6: maximum word count permitted in an expression, or blank if none.
#	7: regular expression matching any substring forcing an expression to be
#		reclassified as a definition, or blank if none.
#	8: regular expression matching a preposed annotation not to be counted,
#		or blank if none.
#	9+: columns containing expressions that may contain definitional parts.

#'dftag.pl'          => [ '⫷df⫸', 1, 2 ],
# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#	0: definition tag.
#	1+: columns containing definitions.

#'mitag.pl'          => [ 2, '⫷mi⫸' ],
# Tags meaning identifiers.
# Arguments:
#	0: column that contains meaning identifiers.
#	1: meaning-identifier tag.

#'wcretag.pl'        => [ '⫷wc:', '⫸', '⫷wc⫸', '⫷md:gram⫸', 1, 2 ],
# Retags word classifications in a tab-delimited source file.
# Arguments:
#	0: input file's wc tag before its content.
#	1: input file's wc tag after its content.
#	2: output file's word-classification tag.
#	3: metadatum tag.
#	4+: columns containing word classifications.

#'wctag.pl'          => [ 1, '⫷wc⫸', '⫷md:gram⫸' ],
# Converts and tags word classifications in a tab-delimited source file.
# Arguments:
#	0: column containing word classifications.
#	1: word-classification tag.
#	2: metadatum tag.

#'mdtag.pl'          => [ 2, '⫷md:gram⫸' ],
# Tags metadata in a tab-delimited source file.
# Arguments:
#	0: column containing metadata.
#	1: metadatum tag.

#'dmtag.pl'          => [ '⫷dm⫸', '‣', 2, 3 ],
# Tags domain expressions in a tab-delimited source file.
# Arguments:
#	0: domain-expression tag.
#	1: inter-expression delimiter, or blank if none.
#	2+: columns containing domain expressions.

#'mnsplit.pl'        => [ '⫷mn⫸', 2 ],
# Splits multi-meaning lines of a tagged source file, eliminating any duplicate output lines.
# Arguments:
#	0: meaning-delimitation tag.
#	1: number (0-based) of the column that may contain multiple meanings.

#'wcshift.pl'        => [ 2, '⫷wc:', '⫸', '⫷wc⫸', '⫷ex⫸', '[^⫷]' ],
# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file.
# Arguments:
#	0: column containing prepended word class specifications.
#	1: start of word-class specification.
#	2: end of word-class specification.
#	3: word-classification tag.
#	4: expression tag.
#	5: regular expression matching any post-tag character.

#'normalize.pl'      => [ '⫷[a-z:]+⫸', '⫷ex⫸', 0, 50, 10, 'eng-000', '⫷exp⫸', '⫷df⫸', ', ' ],
# Normalizes expressions in a tagged source file.
# Arguments:
#	0: tag specification (regular expression).
#	1: expression tag.
#	2: column containing expressions to be normalized.
#	3: minimum score (0 or more) a proposed expression must have in order to be accepted
#		outright as an expression. Every proposed expression with a lower (or no) score is
#		to be replaced with the highest-scoring expression sharing its language variety and
#		degradation, if any such expression has a higher score than it.
#	4: minimum score a proposed expression that is not accepted outright as an expression,
#		or its replacement, must have in order to be accepted as an expression.
#	5: variety UID of expressions to be normalized.
#	6: tag of pre-normalized expression.
#	7: if proposed expressions not accepted as expressions and not having replacements accepted
#		as expressions are to be converted to definitions, definition tag, or blank if they
#		are to be converted to pre-normalized expressions.
#	8: regular expression matching the synonym delimiter if each proposed expression containing
#		such a delimiter is to be treated as a list of synonymous proposed expressions and
#		they are to be normalized if and only if all expressions in the list are
#		normalizable, or blank if not.

#'out-simple-0.pl'   => [ 'final', '0:epo-000', '1:hun-000' ],
# Converts a normally tagged source file to a simple-text varilingual source file,
# eliminating duplicates.
# Arguments:
#	0: version of the output file.
#	1+: specifications (column index and variety UID, colon-delimited) of columns
#		containing expressions.

#'out-simple-2.pl'   => [ 'final', 'rus-000', 'eng-000' ],
# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#	0: version of the output file.
#	1: variety UID of column 0.
#	2: variety UID of column 1.

#'out-full-0.pl'     => [ 'final', '', 2, 2, '0:eng-000', '1:haa-000' ],
# Converts a standard tagged source file to a full-text varilingual source file.
# Arguments:
#	0: version of the output file.
#	1: word classification to annotate all expressions as that have no tagged wc,
#		or blank if none.
#	2: minimum count (2 or more) of definitions and expressions per entry.
#	3: minimum count (1 or more) of expressions per entry.
#	4+: specifications (column index and variety UID, colon-delimited) of columns
#		containing tags (ex, df, dm) requiring variety specifications.

#'out-full-2.pl'     => [ 'final', '', 2, 1, '0:art-259', '2:eng-000' ],
# Converts a standard tagged source file to a full-text bilingual source file, eliminating duplicates.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: version of the output file.
#	3: word classification to annotate all expressions as that have no tagged wc, or blank if none.
#	4: minimum count (2 or more) of definitions and expressions per entry.
#	5: minimum count (1 or more) of expressions per entry.
#	6: column index and variety UID, colon-delimited, of source expression column
#	7: column index and variety UID, colon-delimited, of target expression column
#	8*: specifications (column index and variety UID, colon-delimited) of other columns
#		containing tags (df, dm) requiring variety specifications.

);

### DO NOT MODIFY BELOW THIS LINE ###

$PERL ||= $ENV{PANLEX_PERL} || 'perl';

$PERLOPT ||= $ENV{PANLEX_PERLOPT} || '-C63 -w';

my @CMD = split ' ', "$PERL $PERLOPT";

$SERIALIZEDIR ||= 
    (-d $ENV{PANLEX_TOOLDIR} ? catfile($ENV{PANLEX_TOOLDIR},'serialize') : getcwd);

die "odd number of items in \@TOOLS" unless @TOOLS % 2 == 0;

for (my $i = 0; $i < @TOOLS; $i += 2) {
    die "cannot find $BASENAME-$VERSION.txt" unless -r "$BASENAME-$VERSION.txt";

    my ($tool,$args) = @TOOLS[$i, $i+1];
    my $tool_path = catfile($SERIALIZEDIR, $tool);
    die "cannot find $tool in $SERIALIZEDIR" unless -r $tool_path;
    
    my @cmd = (@CMD, $tool_path, $BASENAME, $VERSION++, @$args);
    system @cmd;
}