# Converts a tab-delimited approver file for uploading to PanLex.

# The basename of the approver file.
BASENAME='aaa-bbb-Author'

# The directory containing serialize scripts. If unset here, it will be set 
# from PANLEX_TOOLDIR if possible, otherwise to the current directory.
#SERIALIZEDIR=.

# The path to the perl executable.
#PANLEX_PERL=/opt/bin/perl

### DO NOT MODIFY SECTION BELOW ###

PERLCMD="${PANLEX_PERL-perl} ${PANLEX_PERLOPT--C63 -w}"

if [[ -z $SERIALIZEDIR && -d $PANLEX_TOOLDIR ]]; then
    SERIALIZEDIR="$PANLEX_TOOLDIR/serialize"
else
    SERIALIZEDIR=.
fi

### DO NOT MODIFY SECTION ABOVE ###

$PERLCMD $SERIALIZEDIR/apostrophe.pl $BASENAME 0 '1:gyd-000' '3:nny-000' '5:eng-000'
# Converts a tab-delimited approver file’s apostrophes.
# Arguments:
#	0: base of the filename.
#	1: version of the file.
#	2+: specifications (column index and variety UID, colon-delimited) of columns
#		possibly requiring apostrophe normalization.

$PERLCMD $SERIALIZEDIR/extag.pl $BASENAME 1 '‣' '⁋' '⫷ex⫸' '⫷mn⫸' 0 2
# Tags all expressions and all intra-column meaning changes in a tab-delimited approver file,
# disregarding any definitional parts.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: synonym delimiter (regular expression), or blank if none.
#	3: meaning delimiter (regular expression), or blank if none.
#	4: expression tag.
#	5: meaning tag.
#	6+: columns containing expressions.

$PERLCMD $SERIALIZEDIR/exdftag.pl $BASENAME 2 '⫷ex⫸' '[^⫷]' '[^⫷ ]' '(?:\([^()]+\)|（[^（）]+）)' '⫷df⫸' 25 3 '[][/,;?!~]' '«[^«»]+»' 2
# Splits definitional expressions into reduced expressions and definitions in an approver file with
# already-tagged expressions and tags the added definitions.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: expression tag in file.
#	3: regular expression matching any post-tag character.
#	4: regular expression matching any post-tag character that is not a space.
#	5: regular expression matching a definitional part of an expression.
#	6: definition tag to be used on definitions.
#	7: maximum character count permitted in an expression, or blank if none.
#	8: maximum word count permitted in an expression, or blank if none.
#	9: regular expression matching any substring forcing an expression to be
#		reclassified as a definition, or blank if none.
#	10: regular expression matching a preposed annotation not to be counted,
#		or blank if none.
#	11+: columns containing expressions that may contain definitional parts.

$PERLCMD $SERIALIZEDIR/dftag.pl $BASENAME 3 '⫷df⫸' 1 2
# Tags all column-based definitions in a tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: definition tag.
#	3+: columns containing definitions.

$PERLCMD $SERIALIZEDIR/mitag.pl $BASENAME 4 2 '⫷mi⫸'
# Tags meaning identifiers.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: column that contains meaning identifiers.
#	3: meaning-identifier tag.

$PERLCMD $SERIALIZEDIR/wcretag.pl $BASENAME 2 '⫷wc:' '⫸' '⫷wc⫸' '⫷md:gram⫸' 1 2
# Retags word classifications in a tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2. input file’s wc tag before its content.
#	3. input file’s wc tag after its content.
#	4: output file’s word-classification tag.
#	5: metadatum tag.
#	6+: columns containing word classifications.

$PERLCMD $SERIALIZEDIR/wctag.pl $BASENAME 5 1 '⫷wc⫸' '⫷md:gram⫸'
# Converts and tags word classifications in a tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: column containing word classifications.
#	3: word-classification tag.
#	4: metadatum tag.

$PERLCMD $SERIALIZEDIR/mdtag.pl $BASENAME 6 2 '⫷md:gram⫸'
# Tags metadata in a tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: column containing metadata.
#	3: metadatum tag.

$PERLCMD $SERIALIZEDIR/dmtag.pl $BASENAME 7 '⫷dm⫸' '‣' 2 3
# Tags domain expressions in a tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: domain-expression tag.
#	3: inter-expression delimiter, or blank if none.
#	4+: columns containing domain expressions.

$PERLCMD $SERIALIZEDIR/mnsplit.pl $BASENAME 8 '⫷mn⫸' 2
# Splits multi-meaning lines of a tagged approver file, eliminating any duplicate output lines.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: meaning-delimitation tag.
#	3: number (0-based) of the column that may contain multiple meanings.

$PERLCMD $SERIALIZEDIR/wcshift.pl $BASENAME 9 2 '«wc:' '»' '⫷wc⫸' '⫷ex⫸' '[^⫷]'
# Replaces prepended word class specifications with post-ex wc tags in a
# tab-delimited approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: column containing prepended word class specifications.
#	3: start of word-class specification.
#	4: end of word-class specification.
#	5: word-classification tag.
#	6: expression tag.
#	7: regular expression matching any post-tag character.

$PERLCMD $SERIALIZEDIR/normalize.pl $BASENAME 10 '⫷[a-z:]+⫸' '⫷ex⫸' 0 50 10 'eng-000' '⫷exp⫸' '⫷df⫸' ', '
# Normalizes expressions in a tagged approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: tag specification (regular expression).
#	3: expression tag.
#	4: column containing expressions to be normalized.
#	5: minimum score (0 or more) a proposed expression must have in order to be accepted
#		outright as an expression. Every proposed expression with a lower (or no) score is
#		to be replaced with the highest-scoring expression sharing its language variety and
#		degradation, if any such expression has a higher score than it.
#	6: minimum score a proposed expression that is not accepted outright as an expression,
#		or its replacement, must have in order to be accepted as an expression.
#	7: variety UID of expressions to be normalized.
#	8: tag of pre-normalized expression.
#	9: if proposed expressions not accepted as expressions and not having replacements accepted
#		as expressions are to be converted to definitions, definition tag, or blank if they
#		are to be converted to pre-normalized expressions.
#	10: regular expression matching the synonym delimiter if each proposed expression containing
#		such a delimiter is to be treated as a list of synonymous proposed expressions and
#		they are to be normalized if and only if all expressions in the list are
#		normalizable, or blank if not.

$PERLCMD $SERIALIZEDIR/out-simple-0.pl $BASENAME 11 'final' '0:epo-000' '1:hun-000'
# Converts a normally tagged approver file to a simple-text varilingual approver file,
# eliminating duplicates.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: version of the output file.
#	3+: specifications (column index and variety UID, colon-delimited) of columns
#		containing expressions.

$PERLCMD $SERIALIZEDIR/out-simple-2.pl $BASENAME 12 'final' 'rus-000' 'eng-000'
# Converts a normally tagged approver file to a simple-text bilingual approver file,
# eliminating duplicates.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: version of the output file.
#	3: variety UID of column 0.
#	4: variety UID of column 1.

$PERLCMD $SERIALIZEDIR/out-full-0.pl $BASENAME 12 'final' '' 2 2 '0:eng-000' '1:haa-000'
# Converts a standard tagged approver file to a full-text varilingual approver file.
# Arguments:
#	0: base of the filename.
#	1: version of the input file.
#	2: version of the output file.
#	3: word classification to annotate all expressions as that have no tagged wc,
#		or blank if none.
#	4: minimum count (2 or more) of definitions and expressions per entry.
#	5: minimum count (1 or more) of expressions per entry.
#	6+: specifications (column index and variety UID, colon-delimited) of columns
#		containing tags (ex, df, dm) requiring variety specifications.

$PERLCMD $SERIALIZEDIR/out-full-2.pl $BASENAME 12 'final' '' 2 1 '0:art-259' '2:eng-000'
# Converts a standard tagged approver file to a full-text bilingual approver file, eliminating duplicates.
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
