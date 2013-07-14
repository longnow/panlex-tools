#!/usr/bin/env perl
# Converts a tab-delimited source file for uploading to PanLex.
use strict;
use utf8;

# The basename of the source file.
my $BASENAME = 'aaa-bbb-Author';

# The initial version to use.
my $VERSION = 0;

# The panlex-tools directory containing the serialize scripts. If unset here,
# will look next in env var PANLEX_TOOLDIR, otherwise use current directory.
my $PANLEX_TOOLDIR;

my @TOOLS = (
    
#'apostrophe'   => { specs => ['1:gyd-000', '3:nny-000', '5:eng-000'] },
# Converts a tab-delimited source file's apostrophes.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns possibly requiring apostrophe normalization.

#'extag'        => { cols => [0, 1] },
# Tags all expressions and all intra-column meaning changes in a tab-delimited 
# source file, disregarding any definitional parts.
# Arguments:
#   cols:     array of columns containing expressions.
#   syndelim: synonym delimiter (regex), or '' if none. default '‣'.
#   mndelim:  meaning delimiter (regex), or '' if none. default '⁋'.
#   extag:    expression tag. default '⫷ex⫸'.
#   mntag:    meaning tag. default '⫷mn⫸'.

#'exdftag'      => { cols => [0, 1], re => '(?:\([^()]+\)|（[^（）]+）)', subre => '[][/,;?!~]' },
# Splits definitional expressions into reduced expressions and definitions in 
# a source file with already-tagged expressions and tags the added definitions.
# Arguments:
#   cols:     array of columns containing expressions that may contain 
#               definitional parts.
#   re:       regex matching a definitional part of an expression, or '' if none.
#   subre:    regex matching any substring forcing an expression to be
#               reclassified as a definition, or '' if none.
#   maxchar:  maximum character count permitted in an expression, or '' if none.
#               default ''. example: 25.
#   maxword:  maximum word count permitted in an expression, or '' if none.
#               default ''. example: 3.
#   extag:    expression tag. default '⫷ex⫸'.
#   dftag:    definition tag. default '⫷df⫸'.
#   postre:   regex matching any post-tag character. default '[^⫷]'.
#   postwre:  regex matching any post-tag character that is not a space;
#               default '[^⫷ ]'.
#   prere:    regex matching a preposed annotation not to be counted, or '' if
#               none. default '⫷[^⫷⫸]+⫸'.

#'dftag'        => { cols => [1, 2] },
# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing definitions.
#   dftag:  definition tag. default '⫷df⫸'.

#'mitag'        => { col => 2 },
# Tags meaning identifiers.
# Arguments:
#   col:    column that contains meaning identifiers.
#   mitag:  meaning-identifier tag. default '⫷mi⫸'.

#'wcretag'      => { cols => [1, 2] },
# Retags word classifications in a tab-delimited source file.
# Arguments:
#   cols:     array of columns containing word classifications.
#   pretag:   input file's wc tag before its content. default '⫷wc:'.
#   posttag:  input file's wc tag after its content. default '⫸'.
#   wctag:    output file's word-classification tag. default '⫷wc⫸'
#   mdtag:    metadatum tag. default '⫷md:gram⫸'.

#'wctag'        => { col => 1 },
# Converts and tags word classifications in a tab-delimited source file.
# Arguments:
#   col:   column containing word classifications.
#   wctag: word-classification tag. default '⫷wc⫸'.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.

#'mdtag'        => { col => 2 },
# Tags metadata in a tab-delimited source file.
# Arguments:
#   col:   column containing metadata.
#   mdtag: metadatum tag. default '⫷md:gram⫸'.

#'dmtag'        => { cols => [2, 3] },
# Tags domain expressions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing metadata.
#   dmtag:  domain-expression tag. default '⫷dm⫸'.
#   delim:  inter-expression delimiter, or '' if none. default '‣'.

#'mnsplit'      => { col => 2 },
# Splits multi-meaning lines of a tagged source file, eliminating any duplicate
# output lines.
# Arguments:
#   col:    column that may contain multiple meanings.
#   delim:  meaning-delimitation tag. default '⫷mn⫸'.

#'wcshift'      => { col => 2 },
# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited source file.
# Arguments:
#   col:      column containing prepended word class specifications.
#   pretag:   start of word-class specification. default '⫷wc:'.
#   posttag:  end of word-class specification. default '⫸'.
#   wctag:    word-classification tag. default '⫷wc⫸'.
#   extag:    expression tag. default '⫷ex⫸'.
#   postre:   regex matching any post-tag character. default '[^⫷]'.

#'normalize'    => { col => 0, uid => 'eng-000', min => 50, mindeg => 10 },
# Normalizes expressions in a tagged source file.
# Arguments:
#   col:      column containing expressions to be normalized.
#   uid:      variety UID of expressions to be normalized.
#   min:      minimum score (0 or more) a proposed expression must have in order 
#               to be accepted outright as an expression. Every proposed 
#               expression with a lower (or no) score is to be replaced with the 
#               highest-scoring expression sharing its language variety and 
#               degradation, if any such expression has a higher score than it.
#   mindeg:   minimum score a proposed expression that is not accepted outright 
#               as an expression, or its replacement, must have in order to be
#               accepted as an expression.
#   failtag:  tag with which to retag proposed expressions not accepted as 
#               expressions and not having replacements accepted as expressions; 
#               '' (blank) if they are to be converted to pre-normalized 
#               expressions. default '⫷df⫸'.
#   ignore:   regex matching expressions to be ignored in normalization; or ''
#               (blank) if none. default ''.
#   delim:    regex matching the synonym delimiter, if each proposed expression
#               containing such a delimiter is to be treated as a list of
#               synonymous proposed expressions and they are to be normalized if
#               and only if all expressions in the list are normalizable; or ''
#               (blank) if not. default ''. example: ', '.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.
#   tagre:    regex identifying any tag. default '⫷[a-z:]+⫸'.

#'out-simple-0' => { specs => [ '0:rus-000', '1:eng-000' ] },
# Converts a normally tagged source file to a simple-text varilingual source file,
# eliminating duplicates.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing expressions.

#'out-simple-2' => { uids => [ 'rus-000', 'eng-000' ] },
# Converts a normally tagged source file to a simple-text bilingual source file,
# eliminating duplicates.
# Arguments:
#   uids:   two-element array containing variety UIDs of columns 0 and 1.

#'out-full-0'   => { specs => [ '0:rus-000', '1:eng-000' ] },
# Converts a standard tagged source file to a full-text varilingual source file.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing tags (e.g., ex, df, dm) requiring variety
#             specifications.
#   mindf:  minimum count (2 or more) of definitions and expressions per entry.
#             default 2.
#   minex:  minimum count (1 or more) of expressions per entry. default 1.
#   wc:     word classification to annotate all expressions as that have no 
#             tagged wc, or '' if none. default ''.

#'out-full-2'   => { specs => [ '0:rus-259', '1:eng-000' ] },
# Converts a standard tagged source file to a full-text bilingual source file, 
# eliminating duplicates. Risky if exdftag or normalize has been used.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing tags (e.g., ex, df, dm) requiring variety
#             specifications.
#   mindf:  minimum count (2 or more) of definitions and expressions per entry.
#             default 2.
#   minex:  minimum count (1 or more) of expressions per entry. default 1.
#   wc:     word classification to annotate all expressions as that have no 
#             tagged wc, or '' if none. default ''.

);

### DO NOT MODIFY BELOW THIS LINE ###

use File::Spec::Functions;

foreach my $dir (grep { $_ && -d $_ } ($ENV{PANLEX_TOOLDIR}, $PANLEX_TOOLDIR)) {
    unshift @INC, catfile($dir, 'serialize');    
    unshift @INC, catfile($dir, 'lib');    
}

require 'run.pl';
run($PANLEX_TOOLDIR || $ENV{PANLEX_TOOLDIR}, $BASENAME, $VERSION, \@TOOLS);