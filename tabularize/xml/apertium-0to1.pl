#!/usr/bin/env perl

# apertium-0to1.pl
# Tabularizes an Apertium .dix file, eliminating duplicate entries.
# Outputs a 6-column table with columns ex, wc, md, ex, wc, md.

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
use Mojo::DOM;

#######################################################

my $BASENAME = 'aaa-bbb-Author';
# Identify the filename base.

my $VERSION = 0;
# Identify the input file's version.

#######################################################

open my $out, '>', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<', "$BASENAME-$VERSION.dix" or die $!;
# Open the input file for reading.

my $xml = do { local $/; <$in> };
# Make the line-break variable temporarily undefined, then read 1 line (which is
# therefore the whole file) from the input file, and identify it as $xml.

my $dom = Mojo::DOM->new($xml);
# Create a Mojo::DOM object to query the document.

my %seen;

foreach my $entry ($dom->find('section e p')->each) {
    my @col;

    push @col, extract_side($entry->at($_)) for qw/l r/;

    next if skip(@col);

    output(@col);
}

foreach my $entry ($dom->find('section e i')->each) {
    my @col = (extract_side($entry)) x 2;

    next if skip(@col);

    output(@col);
}

close $in;
# Close the input file.

close $out;
# Close the output file.

sub extract_side {
    my ($el) = @_;

    my @col = ($el->text, '', '');
    my @wcmd = $el->find('s')->map(attr => 'n')->each; # the side's wc and md

    if ($col[0] ne '' && @wcmd) {
        $col[1] = shift @wcmd;
        $col[2] = join('‣', @wcmd);
    }

    return @col;
}

sub skip {
    return 1 if $_[0] =~ /^\d+$/ && $_[3] =~ /^\d+$/;
    return 1 if $_[0] eq 'prpers' || $_[3] eq 'prpers'; # these are not real entries
    return 0;
}

sub output {
    my $line = join("\t", @_);

    unless (exists $seen{$line}) {
        $seen{$line} = '';
        print $out $line, "\n";
    }
}