### Dedup
# Delete duplicate elements in the specified pseudo-list.
# Arguments:
#    0: pseudo-list.
#    1: delimiting non-meta character.

use utf8;
# Make Perl interpret the script as UTF-8. Calling script's invocation of
# this pragma does not apply to this script, which is imported with a
# “require” statement, i.e. via an “eval `cat dedup.pl`” mechanism.

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

1;
