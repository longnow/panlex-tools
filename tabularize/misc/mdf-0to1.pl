#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

use open IN => ':crlf :encoding(utf8)', OUT => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and convert CRLF to LF if necessary.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

use lib "$ENV{PANLEX_TOOLDIR}/lib";
use PanLex::Util;

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.txt" or die $!;
# Open the input file for reading.

# skip over the MDF header.
while (<$in>) {
    last if /^\s*$/;
}

my (%rec, $lastmarker, $lasttxt);

while (<$in>) {
# For each line of the input file:

    chomp;
    # remove its trailing newline, if present.

    if (my ($marker, $txt) = /^\\([a-z]+) +(.+)$/) {
        # the last marker (if any) is complete, so handle it
        handle_marker($lastmarker, $lasttxt) if defined $lastmarker;

        if ($marker eq 'lx') { # start of a new entry
            output_line();
            %rec = ();
        }

        ($lastmarker, $lasttxt) = ($marker, $txt);
    }
    elsif (! /^(?:\\[a-z]+)\s*?$/) { # continuation of previous line's marker text
        $lasttxt .= ' ' . $_;
    }
}

handle_marker($lastmarker, $lasttxt);
output_line();

close $in;
# Close the input file.

close $out;
# Close the output file.

# called for every marker.
sub handle_marker {
    my ($marker, $txt) = @_;

    if ($marker =~ /^(lx|ps|g[ern])$/) { # lexeme, part of speech, glosses
        $rec{$marker} = $txt;
    }
    elsif ($marker eq 'lc') { # citation form
        $rec{lx} = $txt;
    }
    elsif ($marker eq 'sn' && $txt > 1) {
        output_line();
        delete $rec{$_} for qw(ps ge gr gn);
    }
}

# outputs a single line. called at the end of every record and can also be called within records.
sub output_line {
    return unless exists $rec{lx};
    print $out join("\t", map { exists $rec{$_} ? Trim($rec{$_}) : '' } qw(lx ps ge)), "\n";
}
