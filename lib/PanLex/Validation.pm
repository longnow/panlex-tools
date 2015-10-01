package PanLex::Validation;
use strict;
use parent 'Exporter';
use PanLex::Serialize::Util;

our @EXPORT = qw/validate_spec validate_col validate_uid valid_int validate_array validate_hash validate_cols validate_specs validate_uids validate_tag/;

# dies if the two arguments do not form a valid column and uid spec.
sub validate_spec {
    die "invalid specification: $_[0]" unless $_[0] =~ /^\d+:[a-z]{3}-\d{3}$/;
}

# dies if the argument is not a valid column index.
sub validate_col {
    die "invalid column: $_[0]" unless $_[0] =~ /^\d+$/;
    $_[0] += 0; # un-stringify scalar (affects JSON encoding)
}

# dies if the argument is not a valid language uid.
sub validate_uid {
    die "invalid uid: $_[0]" unless $_[0] =~ /^[a-z]{3}-\d{3}$/;
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

# dies unless the argument is an array reference.
# also calls validate_spec on each element of the array.
sub validate_specs {
    die "expected specs argument to be an array" unless ref $_[0] eq 'ARRAY';
    validate_spec($_) for @{$_[0]};
}

# dies unless the argument is a non-empty array reference.
# also calls validate_uid on each element of the array.
sub validate_uids {
    die "expected a uids argument with at least one column" unless ref $_[0] eq 'ARRAY' && @{$_[0]};
    validate_uid($_) for @{$_[0]};
}

# dies unless the argument is a tag containing a single tag with no content.
# returns the parsed tag.
sub validate_tag {
    my $tags = parse_tags($_[0]);
    die "expected a single tag: $_[0]" unless @$tags == 1;
    die "expected a tag with no contenet: $_[0]" unless $tags->[0][2] eq '';
    return $tags->[0];
}

1;