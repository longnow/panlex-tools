### Trim
# Delete superfluous spaces in the specified string.
# Argument:
#    0: string.

use utf8;
# Make Perl interpret the script as UTF-8. Calling script's invocation of
# this pragma does not apply to this script, which is imported with a
# “require” statement, i.e. via an “eval `cat trim.pl`” mechanism.

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

1;
