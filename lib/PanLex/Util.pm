package PanLex::Util;
use strict;
use utf8;
use base 'Exporter';

use vars qw/@EXPORT/;
@EXPORT = qw/Trim Dedup Delimiter DelimiterIf/;

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

    $txt =~ s/ *[$indelim] *(?![^()]*\))/$outdelim/g;

    return $txt;
}

### DelimiterIf
# Replace non-parenthesized delimiters in a string with a standard delimiter, 
# if all delimited expressions match a particular regular expression.
# Arguments:
#   0: input string.
#   1: string containing a set of non-standard delimiters to match.
#   2: standard delimiter.
#   3: regular expression to apply to each expression.

sub DelimiterIf {
    my ($txt, $indelim, $outdelim, $re) = @_;

    my @ex = split / *[$indelim] *(?![^()]*\))/, $txt;

    foreach my $ex (@ex) {
        return $txt unless $ex =~ /$re/;
    }

    return join $outdelim, @ex;
}

1;