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


use utf8;

%c2l=(
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

%l2c=reverse %c2l;


open (FILE, $ARGV[0]);
binmode(FILE, ':utf8');
undef $/;
$file=<FILE>;

@chars=split ('', $file);
foreach $char (@chars){

   if (exists $c2l{$char}){
         $output.=$c2l{$char};
      } else {$output.=$char}
}

print $output;
