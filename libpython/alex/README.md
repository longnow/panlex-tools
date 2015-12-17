# PLTK basic documentation

Most functions take in "entries" as their first parameter, and returns a modified "entries" as output. "entries" is a list of lists, where each sublist corresponds to a row/meaning in the source. These might or might not be lists in and of themselves, but probably are strings (it probably should have been standardized at the beginning but wasn't, so the user just has to keep track).

`entries = [ [ eng1, pos1, jpn1 ], [ eng2, pos2, jpn2 ], ... ]`

or

`entries = [ [ [eng1_1, eng1_2], pos1, [jpn1] ], [ [eng2], pos2, [jpn2_1, jpn2_2], ... ]`

## Functions

### `preprocess`

Performs preprocessing of things that should always be done to every file: e.g. converting fullwidth numbers to halfwidth, ellipses to standard format, stripping out excess whitespace, etc.

### `split_outside_parens`

Splits strings within a column to lists on the given delimiter, ignoring anything inside any given parenthetical characters. Also detects and ignores full sentences (experimental)

### `make_paren_regex`

Returns a regular expression string for matching any parenthetical content, including any variety of nested elements with any given (matching) parenthetical characters, up to a certain number of layers deep (default 10).

### `exdfprep`

Parenthesizes "definitional" parts of an expression (e.g. "the" or "to", to be "definitionalized" during serialization with the `exdftag` script), and adding appropriate pretagged elements.

#### `EXDFPREP_RULES`

Dictionary defining the conversions to perform during exdfprep, by language variety. The values of each are dictionaries whose keys are integers that indicate the order to perform operations. The value of each integer is a dictionary whose keys are regular expressions to search for in the text. The values of these are ordered pairs (tuples of length 2), where the first element is a regex corresponding to the replacement text for the matched sequence, and the second element the text of additional properties or classifications to pre-tag expressions with any matching sequence.

Example (these are not the real rules):

```
EXDFPREP_RULES = {
  'eng-000' : {     # language variety

    1 : {           # priority

      r'^(to) ' :   # regex to match

        ( r'(\1) ', # regex for replacement text

           # classification to add (pretag)
           '⫷dcs2:art-303⫸PartOfSpeechProperty⫷dcs:art-303⫸Verbal' ), 

      r'^(the) ' :  # regex to match
        (r'(\2)',   # regex for replacement text
          ''),      # classification

      ...

    },
    2: {            # priority
      r'^(kind of) (.*)$' : # regex to match
        ( r'(\1) \2',       # regex for replacement text
          r'⫷mcs2:art-300⫸IsA⫷mcs⫸\2'),  # classification
    },
    ...
    },
  },
  ...
}
```

### `mnsplit`

Splits a single line into multiple lines on some meaning delimiter (typically a semicolon or the like).

### `separate_parentheticals`

Separates delimited text within parentheses into multiple parenthetical statements.

e.g.: (red, green, blue) --> (red) (green) (blue)

### `convert_between_cols`

Takes a dictionary of regex replacements (from : to), and deposits each "to" side either to a new column or the same as the original.

### `splitcol`

Splits a column with a string cell into lists.

### `joincol`

Joins a column with a list cell into strings.

### `remove_nested_parens`

Removes any parentheses around parenthetical information located inside other sets of parentheses.

e.g.: (foo [bar] baz (qux ([hoge] piyo))) --> (foo bar baz qux hoge piyo)

### `prepsyns`

Performs a variety of operations on a column, language-variety-dependent, to appropriately separate synonyms. Steps: split_outside_parens --> exdfprep --> join with synonym delimiter (typically ‣) --> remove_nested_parens.

### `resolve_xrefs`

Resolves cross-references ("see XXX") by copying information from other entries.

### `normalize`

Contacts the PanLex API and only retains entries with expressions that return normalize scores at a minimum threshold. NOTE: this doesn't pretag anything, it just completely discards entries that return under the given threshold.

### `jpn_normalize`

Uses MeCab (https://taku910.github.io/mecab/#download) to segment Japanese text and pretag definitions.

### `lemmatize_verb`

Uses TextBlob to attempt to return a given string with all verbs converted to their lemmatic forms.

### `expsplit`

Attempts to split texts properly that indicate synonyms with some contextual delimiter, e.g. with a slash ("spend money/time") or parentheses ("colo(u)r").

### `tsv_to_entries`

Reads in a standard tsv file to an "entries" formatted list.

### `delete_col`

Deletes a full column from entries.
