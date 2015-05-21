package PanLex::MungeJson;
use strict;
use parent 'Exporter';

our @EXPORT = qw/munge_json/;

# Make JSON output a bit less pretty.
sub munge_json {
    my ($json) = @_;
    $json =~ s/(?<= : \{)\n([^}]+)(?=\})/munge_json_lines($1)/ge;
    return $json;
}

sub munge_json_lines {
    my ($lines) = @_;
    $lines =~ s/\n/ /g;
    $lines =~ s/ +/ /g;
    return $lines;
}

1;