package PanLex::Util;
use strict;
use utf8;
use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
use parent 'Exporter';
use Unicode::Normalize 'NFC';

our @EXPORT = qw(Trim NormTrim Dedup Delimiter DelimiterIf DelimiterIfRegex ExpandParens ExpandParensEachEx EachEx LoadMap MapStr NestedParensToBrackets);

### Trim
# Delete superfluous spaces in the specified string.
# Argument:
#    0: string.
sub Trim {
    my $ret = $_[0];
    # Identify the specified string.

    $ret =~ s/ {2,}/ /g;
    # Collapse all multiple spaces in it.

    $ret =~ s/ (?=[⁋‣\t⫷⫸]|$)//g;
    # Delete all trailing spaces in it.

    $ret =~ s/(?:^|[⁋‣\t⫸])\K //g;
    # Delete all leading spaces in it.

    return $ret;
    # Return the modified string.
}

### NormTrim
# Normalize the specified string according to the PanLex standard and trim leading
# and trailing spaces.
# Normalization:
# Convert the string to its normalization form C, then delete any characters with
# Other Unicode General Category properties (e.g., zero-width space), then replace
# and sequences of characters with Separator Unicode General Category properties with
# single spaces, then remove any leading and any trailing space, and then return the
# converted string.
# Trimming:
# Delete every space that immediately precedes any of the following: a standard meaning
# delimiter, a standard synonym delimiter, a tab, an opening tag bracket, a closing tag
# bracket, or the end of the string.
# Delete every space that immediately follows any of the following: a standard meaning
# delimiter, a standard synonym delimiter, a tab, a closing tag bracket, or the beginning
# of the string.
# Arguments:
#   0: a string.
sub NormTrim {

    my $ret = NFC($_[0]);
    # Identify the normalization form C (canonical decomposition followed by canonical
    # composition) of the specified string. (The normalization form was changed from KC to K,
    # and so the function was changed from NFKC to NFC, on 2010/01/30 because it was judged that
    # tonal superscripts were legitimately distinct from numerals. Any other compatibility
    # decompositions to be retained can be implemented à la carte.)

    $ret =~ s/\p{C}+//g;
    # Delete any sequence of 1 or more characters in it with Other Unicode General Category
    # properties.

    my @seg = (split /\t/, $ret, -1);
    # Identify its tab-delimited segments.

    foreach my $s (@seg) {
    # For each of them:

        $s =~ s/\p{Z}+/ /g;
        # Replace any sequence of 1 or more characters in it with the Separator Unicode
        # General Category properties with a single space.

    }

    $ret = (join "\t", @seg);
    # Reidentify the string.

    $ret =~ s/ (?=[⁋‣\t⫷⫸]|$)//g;
    # Delete all trailing spaces in it.

    $ret =~ s/(?:^|[⁋‣\t⫸])\K //g;
    # Delete all leading spaces in it.

    return $ret;
    # Return the normalized string.

}

### Dedup
# Delete duplicate elements in the specified pseudo-list.
# Arguments:
#    0: pseudo-list.
#    1: delimiting non-meta character.
sub Dedup {
    my ($list, $delim) = @_;

    my %el;
    foreach my $i (split /$delim/, $list) {
    # For each of them:

        $el{$i} = '';
        # Add it to the table of elements, if not already in it.

    }

    return join($delim, keys %el);
    # Return the specified pseudo-list, without any duplicate elements,
    # in random order.
}

### Delimiter
# Replace non-parenthesized delimiters in a string with a standard delimiter.
# Arguments:
#   0: input string.
#   1: string containing a set of non-standard delimiters to match.
#   2: standard delimiter.
sub Delimiter {
    my ($txt, $indelim, $outdelim) = @_;

    $txt =~ s/ *[$indelim] *(?![^()（）]*[)）])/$outdelim/g;

    return $txt;
}

### DelimiterIf
# Replace non-parenthesized delimiters in a string with a standard delimiter, 
# if all delimited expressions match a particular condition.
# Arguments:
#   0: input string.
#   1: string containing a set of non-standard delimiters to match.
#   2: standard delimiter.
#   3: reference to a sub returning true if the condition is met. the sub receives
#        one argument, the expression.
sub DelimiterIf {
    my ($txt, $indelim, $outdelim, $sub) = @_;

    my @ex = split / *[$indelim] *(?![^()（）]*[)）])/, $txt, -1;

    foreach my $ex (@ex) {
        return $txt unless $sub->($ex);
    }

    return join $outdelim, @ex;
}

### DelimiterIfRegex
# Replace non-parenthesized delimiters in a string with a standard delimiter, 
# if all delimited expressions match a particular regular expression.
# Arguments:
#   0: input string.
#   1: string containing a set of non-standard delimiters to match.
#   2: standard delimiter.
#   3: regular expression.
sub DelimiterIfRegex {
    my ($txt, $indelim, $outdelim, $re) = @_;

    $re = qr/$re/;

    return DelimiterIf($txt, $indelim, $outdelim, sub { $_[0] =~ $re });
}

### ExpandParens
# Expand expression with an optional parenthesized portion or portions into two 
# or more expressions separated by the standard synonym delimiter, both with and 
# without the parenthesized portion(s).
# Arguments:
#   0: input string containing a single expression with zero or more optional
#       parenthesized portions.
sub ExpandParens {
    my ($txt) = @_;

    return join('‣', _ExpandParens($txt));
}

sub _ExpandParens {
    return map { 
        my @pieces;
        if (@pieces = /(^.*[^ ])\(([^ ]+)\)(.*$)/) {
            _ExpandParens("$pieces[0]$pieces[1]$pieces[2]", _JoinPieces(@pieces));
        }
        elsif (@pieces = /(^.*)\(([^ ]+)\)([^ ,;].*$)/) {
            _ExpandParens("$pieces[0]$pieces[1]$pieces[2]", _JoinPieces(@pieces));
        }
        else {
            ($_);
        }
    } @_;
}

sub _JoinPieces {
    my ($before, $inside, $after) = @_;

    if ($inside =~ /^\p{Uppercase}/ && ($before eq '' || $before =~ /\W$/u)) {
        $after = ucfirst $after;
    }

    return "$before$after";
}

### ExpandParensEachEx
# Calls ExpandParens on each expression in a list of expressions delimited by the
# standard synonym and meaning delimiters.
# Arguments:
#   0: input string containing a list of expressions with zero or more optional
#       parenthesized portions.
sub ExpandParensEachEx {
    return EachEx($_[0], \&ExpandParens);
}


### EachEx
# Apply a function to each expression in a list of expressions delimited by the
# standard synonym and meaning delimiters.
# Arguments:
#   0: input string.
#   1: reference to a sub that will transform each expression and return the result.
#        the sub receives one argument, the expression.
sub EachEx {
    my ($txt, $sub) = @_;

    my @ex = split /([‣⁋])/, $txt;

    for (my $i = 0; $i < @ex; $i += 2) {
        $ex[$i] = $sub->($ex[$i]);
    }

    return join('', @ex);
}

### LoadMap
# Loads a map file, returning a hashref.
# Arguments:
#   0: map file path.
#   1: column delimiter (default "\t").
sub LoadMap {
    my ($path, $delim) = @_;
    $delim //= "\t";

    my $map;

    open my $fh, '<', $path or die $!;

    while (<$fh>) {
        chomp;

        my ($from, $to) = split $delim, $_, 2;

        $map->{$from} = $to;
    }

    return $map;
}

### MapStr
# Converts string characters according to a supplied mapping.
# Arguments:
#   0: the string.
#   1: the mapping (hashref).
sub MapStr {
    my ($str, $map) = @_;

    my $output = '';

    foreach my $chr (split //, $str) {
        $output .= exists $map->{$chr} ? $map->{$chr} : $chr;
    }

    return $output;
}

### NestedParensToBrackets
# Converts nested parentheses to brackets in a string.
# Arguments:
#   0: the string.
sub NestedParensToBrackets {
    my ($str) = @_;

    my $count = 0;
    $str =~ s/ ( \( (?{ $count++ }) | \) (?{ $count-- }) ) /_MapParenToBracket($1, $count)/gex;

    return $str;
}

sub _MapParenToBracket {
    my ($char, $count) = @_;

    return '[' if $char eq '(' && $count > 1;
    return ']' if $char eq ')' && $count > 0;
    return $char;
}

1;