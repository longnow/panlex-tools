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

use open IO => ':raw:encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

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

    foreach my $side (qw/l r/) {
        my $el = $entry->at($side);
        push @col, $el->text; # the side's expression

        my @wcmd = $el->find('s')->map(attr => 'n')->each; # the side's wc and md

        if ($col[-1] ne '' && @wcmd) {
            push @col, shift @wcmd;
            push @col, join('‣', @wcmd);
        } else {
            push @col, '', '';            
        }
    }

    next if $col[0] =~ /^\d+$/ && $col[3] =~ /^\d+$/;
    next if $col[0] eq 'prpers' || $col[3] eq 'prpers'; # these are not real entries

    my $line = join("\t", @col);

    unless (exists $seen{$line}) {
        $seen{$line} = '';
        print $out $line, "\n";
    }
}

close $in;
# Close the input file.

close $out;
# Close the output file.
