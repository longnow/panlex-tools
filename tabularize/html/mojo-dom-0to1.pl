#!/usr/bin/env perl

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8.

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

open my $out, '>:encoding(utf8)', ("$BASENAME-" . ($VERSION + 1) . '.txt') or die $!;
# Create or truncate the output file and open it for writing.

open my $in, '<:encoding(utf8)', "$BASENAME-$VERSION.html" or die $!;
# Open the input file for reading.

my $html = do { local $/; <$in> };
# Read in the whole HTML input.

my $dom = Mojo::DOM->new($html);
# Create a Mojo::DOM object to query the HTML document.

close $in;
# Close the input file.

close $out;
# Close the output file.
