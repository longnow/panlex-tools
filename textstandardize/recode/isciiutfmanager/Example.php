<?php

require_once("UnicodeManager.class.php");

$converter = new UnicodeManager();

header('Content-Type: text/html; charset=utf-8');
print "<BR>". $converter->convert2utf("ºèÔÚÏ ÊÚºÏÚ  Ì³è³Ú ÂÛÑ ÂÞ¤Ï ÌÞ¢µÉÑÜ µÆèÆÚ ÏåÈÚ ¨¿Ä  ÌÞ¢µ  ×åÍÚÊÜÆ µá¢ØÞ¡ ÊÛÈÝÑ ");


?>
