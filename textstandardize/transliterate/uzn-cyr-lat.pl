#!/usr/bin/perl
#################################################################
#:: Programmer: Paul Rodrigues (prrodrig@indiana.edu)
#:: Company   : Indiana University
#:: Procedure : Uzbek Cyrillic-->Latin Conversion
#:: Purpose   : Converts from Uzbek Cyrillic to Latin using Uzbekistan's
#::             1995 Latin script law. 
#::
#::             The conversion table comes from:"Marhamat Uzbek
#::             Coursebook for Beginners."  Nigora Sharipova
#::             and Hanneke Ykema. AWB Publishing. 2002.
#:: Version   : 10-24-04-1  18:38
#:: Description of Version : Creation (10-24-04; prrodrig)
#################################################################


# EXAMPLE:
#  perl /Volumes/Data/bin/uzbek_cyrillic-latin_conversion.pl  infile.txt > outfile.txt

use warnings 'FATAL', 'all';
# Make every warning fatal.

use strict;
# Require strict checking of variable references, etc.

use utf8;
# Make Perl interpret the script as UTF-8 rather than bytes.

use open IO => ':raw :encoding(utf8)';
# Set UTF-8 as the default for opening files, and turn off automatic newline conversion.

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';
# make STDOUT and STDERR print in UTF-8.

my %c2l = (
    'А'=>'A',
    'Б'=>'B',
    'В'=>'V',
    'Г'=>'G',
    'Д'=>'D',
    'Е'=>'Ye',
    'Ё'=>'Yo',
    'Ж'=>'J',
    'З'=>'Z',
    'И'=>'I',
    'Й'=>'Y',
    'К'=>'K',
    'Л'=>'L',
    'М'=>'M',
    'Н'=>'N',
    'О'=>'O',
    'П'=>'P',
    'Р'=>'R',
    'С'=>'S',
    'Т'=>'T',
    'У'=>'U',
    'Ф'=>'F',
    'Х'=>'X',
    'Ц'=>'Ts',
    'Ч'=>'Ch',
    'Ш'=>'Sh',
    'Ъ'=>"'",
    'Ь'=>'',
    'Э'=>'E',
    'Ю'=>'Yu',
    'Я'=>'Ya',
    'Ў'=>"O'",
    'Қ'=>'Q',
    'Ғ'=>"G'",
    'Ҳ'=>'H',

    'а'=>'a',
    'б'=>'b',
    'в'=>'v',
    'г'=>'g',
    'д'=>'d',
    'е'=>'ye',
    'ё'=>'yo',
    'ж'=>'j',
    'з'=>'z',
    'и'=>'i',
    'й'=>'y',
    'к'=>'k',
    'л'=>'l',
    'м'=>'m',
    'н'=>'n',
    'о'=>'o',
    'п'=>'p',
    'р'=>'r',
    'с'=>'s',
    'т'=>'t',
    'у'=>'u',
    'ф'=>'f',
    'х'=>'x',
    'ц'=>'ts',
    'ч'=>'ch',
    'ш'=>'sh',
    'ъ'=>"'",
    'ь'=>'',
    'э'=>'e',
    'ю'=>'yu',
    'я'=>'ya',
    'ў'=>"o'",
    'қ'=>'q',
    'ғ'=>"q'",
    'ҳ'=>'h',
);

my %l2c = reverse %c2l;

open my $fh, '<', $ARGV[0] or die $!;
my $file = do { local $/; <$fh> };

foreach my $char (split ('', $file)) {
    if (exists $c2l{$char}) {
        print $c2l{$char};
    } else {
        print $char;
    }
}

close $fh;