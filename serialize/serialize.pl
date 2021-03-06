#!/usr/bin/env perl
# Converts a tab-delimited source file for uploading to PanLex.
use strict;
use warnings 'FATAL', 'all';
use utf8;

# The basename of the source file.
my $BASENAME = 'aaa-bbb-Author';

# The initial version to use.
my $VERSION = 1;

# Array of default specifications (column index + colon + variety UID)
# for apostrophe and out-full-0.
my @SPECS = qw( 0:eng-000 1:rus-000 );

my @TOOLS = (

#'apostrophe'   => { specs => \@SPECS },
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

#'normalizedf'  => { col => 0, uid => 'eng-000', min => 100, mindeg => 10 },
# Normalizes expressions in a tagged source file by matching them against definitions.
# Arguments:
#   col:      column containing expressions to be normalized.
#   uid:      variety UID of expressions to be normalized.
#   min:      minimum score (0 or more) a proposed expression must have in order to be
#               accepted outright as an expression. Every proposed expression with a
#               lower (or no) score is to be replaced with the highest-scoring
#               definition sharing its language variety and degradation, if any
#               such definition has a higher score than it.
#   mindeg:   minimum score an expression’s definitional replacement must have in order
#               to be order to be accepted.
#   strict:   set to 1 to only accept replacements differing in parentheses, 0
#               to accept all replacements. default 1.
#   grp:      array of source group IDs whose meanings are to be ignored in
#               normalization; [] if none. default [].
#   log:      set to 1 to log normalize scores to normalizedf.json, 0 otherwise.
#               default 1.
#   ignore:   regex matching expressions to be ignored in normalization; or ''
#               (blank) if none. default ''.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.

#'exdftag'      => { cols => [0, 1], re => '(?:\([^()]+\)|（[^（）]+）)', subre => '[][/,;?!~]' },
# Splits definitional expressions into reduced expressions and definitions in
# a source file with already-tagged expressions and tags the added definitions.
# Arguments:
#   cols:     array of columns containing expressions that may contain
#               definitional parts.
#   re:       regex matching a definitional part of an expression, or '' if none.
#   subre:    regex matching any substring forcing an expression to be
#               reclassified as a definition (or deleted if in a reduced string
#               left by removal of definitional parts), or '' if none.
#   maxchar:  maximum character count permitted in an expression, or '' if none.
#               default ''. example: 25.
#   maxword:  maximum word count permitted in an expression, or '' if none.
#               default ''. example: 3.
#   extag:    expression tag. default '⫷ex⫸'.
#   dftag:    definition tag. default '⫷df⫸'.

#'dftag'        => { cols => [1] },
# Tags all column-based definitions in a tab-delimited source file.
# Arguments:
#   cols:   array of columns containing definitions.
#   dftag:  definition tag. default '⫷df⫸'.
#   delim:  inter-definition delimiter, or '' if none. default '‣'.

#'csppmap'      => { cols => [1] },
# Arguments:
#   cols:       array of columns containing data to be mapped.
#   file:       name of the mapping file. default 'csppmap.txt'.
#   type:       type of the mapping file ('d' for denotation, 'm' for meaning).
#                   default 'd'.
#   delim:      inter-classification/property delimiter in file and columns.
#                   default '‣'.
#   default:    meaning or denotation attribute expression to use for unconvertible
#                 items, or 'pass' if they should be left unchanged, or '' if they
#                 should be deleted. default 'art-303⁋LinguisticProperty', where
#                 'art-303' is the expression's UID, and 'LinguisticProperty' is
#                 its text.
#   mapdefault: attribute expression to use when the mapping file property column
#                 is '*'. default 'art-303⁋LinguisticProperty', where 'art-303' is
#                 the expression's UID, and 'LinguisticProperty' is its text.
#   degrade:    whether to compare texts in their PanLex degraded form.
#                 default 1.
#   log:        set to 1 to log unconvertible items to csppmap.log, 0 otherwise.
#                 default 1.

#'dcstag'       => { cols => [1] },
# Tags denotation classifications.
# Arguments:
#   cols:   array of columns containing denotation classifications.
#   delim:  inter-classification delimiter, or '' if none. default '‣'.
#   prefix: string to prefix to each classification before parsing, or '' if none.
#             default ''.

#'dpptag'       => { cols => [1] },
# Tags denotation properties.
# Arguments:
#   cols:   array of columns containing denotation properties.
#   delim:  inter-property delimiter, or '' if none. default '‣'.
#   prefix: string to prefix to each property before parsing, or '' if none.
#             default ''.

#'copydntag'      => { fromcol => 1, tocols => [0] },
# Copies tagged denotation classifications or properties from a column to after each
#   expression (standardly tagged) in a list of columns, then sets the column to ''.
# Arguments:
#   fromcol:  column containing tag(s) to be copied.
#   tocols:   array of columns containing tagged items.

#'mcsmap'       => { cols => [1] },
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

#'mcstag'       => { cols => [1] },
# Tags meaning classifications.
# Arguments:
#   cols:   array of columns containing meaning classifications.
#   delim:  inter-classification delimiter, or '' if none. default '‣'.
#   prefix: string to prefix to each classification before parsing, or '' if none.
#             default ''. example 'art-300⁋HasContext⁋'.

#'mpptag'       => { cols => [1] },
# Tags meaning properties.
# Arguments:
#   cols:   array of columns containing meaning properties.
#   delim:  inter-property delimiter, or '' if none. default '‣'.
#   prefix: string to prefix to each property before parsing, or '' if none.
#             default ''. example 'art-301⁋identifier⁋'.

#'mnsplit'      => { col => 2 },
# Splits multi-meaning lines of a tagged source file.
# Arguments:
#   col:    column that may contain multiple meanings.
#   delim:  meaning-delimiter tag. default '⫷mn⫸'.

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
#               accepted as an expression. pass '' to disable replacement.
#   grp:      array of source group IDs whose meanings are to be ignored in
#               normalization; [] if none. default [].
#   log:      set to 1 to log normalize scores to normalize.json, 0 otherwise.
#               default 1.
#   failtag:  tag with which to retag proposed expressions not accepted as
#               expressions and not having replacements accepted as expressions;
#               '' (blank) if they are to be converted to pre-normalized
#               expressions. default '⫷df⫸'.
#   ignore:   regex matching expressions to be ignored in normalization; or ''
#               (blank) if none. default ''.
#   propcols: array of columns to which the extag to failtag replacement should
#               be propagated when it takes place; [] if none. default [].
#   delim:    regex matching the synonym delimiter, if each proposed expression
#               containing such a delimiter is to be treated as a list of
#               synonymous proposed expressions and they are to be normalized if
#               and only if all expressions in the list are normalizable; or ''
#               (blank) if not. default ''. example: ', '.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.

#'spellcheck'   => { col => 0, engine => 'aspell', dict => 'en_US' },
# Spell-checks expressions in a tagged source file.
# aspell requires Text::Aspell; hunspell requires Text::Hunspell.
# Arguments:
#   col:      column containing expressions to be spell-checked.
#   engine:   spell-check engine to use ('aspell' or 'hunspell').
#   dict:     dictionary to use. for aspell, this is one of the names returned
#               by `aspell dicts`. for hunspell, this is the full path to the
#               dictionary file, excluding the '.aff' or '.dic' extension.
#   ignore:   regex matching expressions to be ignored in spell checking; or ''
#               (blank) if none. default ''.
#   failtag:  tag with which to retag proposed expressions not accepted as
#               expressions; '' (blank) if they are to be converted to
#               pre-normalized expressions. default '⫷df⫸'.
#   extag:    expression tag. default '⫷ex⫸'.
#   exptag:   pre-normalized expression tag. default '⫷exp⫸'.

#'replace'      => { cols => [1], from => '⫷fail⫸', to => '⫷ex⫸' },
# Replaces strings in a tab-delimited source file.
# Arguments:
#   cols:   array of columns to be processed.
#   from:   regex matching any string(s) to be replaced.
#   to:     new string to use.

#'out-full-0'   => { specs => \@SPECS },
# Converts a standard tagged source file to a full-text varilingual source file.
# Arguments:
#   specs:  array of specifications (column index + colon + variety UID) of
#             columns containing tags (e.g., ex, df, mcs, dcs) requiring variety
#             specifications.
#   mindf:  minimum count (0 or more) of definitions and expressions per entry.
#             default 2.
#   minex:  minimum count (0 or more) of expressions per entry. default 1.
#   remove_tags: regular expression matching tag types to be removed prior to
#             serialization, or '' if none. default '^(?:exp|rm)$'.
#   error:  indicates what to do when certain common errors are detected. use
#             'mark' to mark errors in the output file, 'fail' to immediately
#             abort, and 'ignore' to do nothing. default 'mark'.

);

### DO NOT MODIFY BELOW THIS LINE ###

use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Serialize;
serialize($BASENAME, $VERSION, \@TOOLS);
