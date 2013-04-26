package PanLex::Validation;
use strict;
use base 'Exporter';

use vars qw/@EXPORT/;
@EXPORT = qw/validate_spec validate_col validate_uid valid_int/;

# dies if the two arguments do not form a valid column and uid spec.
sub validate_spec {
    my ($col, $uid) = @_;
    validate_col($col);
    validate_uid($uid);
}

# dies if the argument is not a valid column index.
sub validate_col {
    die "invalid column: $_[0]" unless $_[0] =~ /^\d+$/ && $_[0] >= 0;
}

# dies if the argument is not a valid language uid.
sub validate_uid {
    my ($uid) = @_;
    die "invalid uid: $uid" unless $uid =~ /^[a-z]{3}-\d{3}$/;
}

# returns whether the argument is a valid integer.
sub valid_int {
    return $_[0] =~ /^\d+$/;
}

1;