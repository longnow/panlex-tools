<?php

require_once("UnicodeManager.class.php");

$converter = new UnicodeManager();

header('Content-Type: text/html; charset=utf-8');
print "<BR>". $converter->convert2utf("����� �ں��  ̳�� ��� �ޤ� �ޢ���� ����� ���� ���  �ޢ�  ������� ���ޡ ����� ");


?>
