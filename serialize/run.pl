# this file is needed for backwards compat only

use strict;
use PanLex::Serialize;

sub run {
    my $PANLEX_TOOLDIR = shift;
    $ENV{PANLEX_TOOLDIR} = $PANLEX_TOOLDIR;
    serialize(@_);
}

1;