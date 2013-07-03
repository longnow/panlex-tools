package PanLex::Validation;
use strict;
use base 'Exporter';

use vars qw/@EXPORT/;
@EXPORT = qw/validate_spec validate_col validate_uid valid_int validate_array validate_hash validate_cols/;

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

# dies if the argument is not an array reference.
sub validate_array {
    die "expected an array of arguments" unless ref $_[0] eq 'ARRAY';
}

# dies if the argument is not a hash reference.
sub validate_hash {
    die "expected a hash of arguments" unless ref $_[0] eq 'HASH';
}

# dies unless the argument is a non-empty array reference.
# also calls validate_col on each element of the array.
sub validate_cols {
    die "expected a cols argument with at least one column" unless ref $_[0] eq 'ARRAY' && @{$_[0]};
    validate_col($_) for @{$_[0]};
}

1;