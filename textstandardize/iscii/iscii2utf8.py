#!env python3
#coding: utf-8


from pprint import pprint


def get_map(codepage):
    '''
    Values of codepage
    * 57002 Devanagari (Hindi, Marathi, Sanskrit, Konkani)
    * 57003 Bengali
    * 57004 Tamil
    * 57005 Telugu
    * 57006 Assamese (same as Bengali)
    * 57007 Oriya
    * 57008 Kannada
    * 57009 Malayalam
    * 57010 Gujarati
    * 57011 Punjabi (Gurmukhi)
    '''
    if not (57002 <= codepage <= 57011):
        raise Exception('Invalid codepage. Valid values are 57002 to 57011 (inclusive)')
    if codepage == 57002:
        s = 0x900
    elif codepage == 57003 or codepage == 57006:
        s = 0x980
    elif codepage == 57004:
        s = 0xb80
    elif codepage == 57005:
        s = 0xc00
    elif codepage == 57007:
        s = 0xb00
    elif codepage == 57008:
        s = 0xc80
    elif codepage == 57009:
        s = 0xd00
    elif codepage == 57010:
        s = 0xa80
    elif codepage == 57011:
        s = 0xa00
    ret = {
        chr(161): chr(s+0x01),
        chr(162): chr(s+0x02),
        chr(163): chr(s+0x03),
        chr(164): chr(s+0x05),
        chr(165): chr(s+0x06),
        chr(166): chr(s+0x07),
        chr(167): chr(s+0x08),
        chr(168): chr(s+0x09),
        chr(169): chr(s+0x0a),
        chr(170): chr(s+0x0b),
        chr(171): chr(s+0x0e),
        chr(172): chr(s+0x0f),
        chr(173): chr(s+0x10),
        chr(174): chr(s+0x0d),
        chr(175): chr(s+0x12),
        chr(176): chr(s+0x13),
        chr(177): chr(s+0x14),
        chr(178): chr(s+0x11),
        chr(179): chr(s+0x15),
        chr(180): chr(s+0x16),
        chr(181): chr(s+0x17),
        chr(182): chr(s+0x18),
        chr(183): chr(s+0x19),
        chr(184): chr(s+0x1a),
        chr(185): chr(s+0x1b),
        chr(186): chr(s+0x1c),
        chr(187): chr(s+0x1d),
        chr(188): chr(s+0x1e),
        chr(189): chr(s+0x1f),
        chr(190): chr(s+0x20),
        chr(191): chr(s+0x21),
        chr(192): chr(s+0x22),
        chr(193): chr(s+0x23),
        chr(194): chr(s+0x24),
        chr(195): chr(s+0x25),
        chr(196): chr(s+0x26),
        chr(197): chr(s+0x27),
        chr(198): chr(s+0x28),
        chr(199): chr(s+0x29),
        chr(200): chr(s+0x2a),
        chr(201): chr(s+0x2b),
        chr(202): chr(s+0x2c),
        chr(203): chr(s+0x2d),
        chr(204): chr(s+0x2e),
        chr(205): chr(s+0x2f),
        chr(206): chr(s+0x5f),
        chr(207): chr(s+0x30),
        chr(208): chr(s+0x31),
        chr(209): chr(s+0x32),
        chr(210): chr(s+0x33),
        chr(211): chr(s+0x34),
        chr(212): chr(s+0x35),
        chr(213): chr(s+0x36),
        chr(214): chr(s+0x37),
        chr(215): chr(s+0x38),
        chr(216): chr(s+0x39),
        chr(217): '\u25cc',
        chr(218): chr(s+0x3e),
        chr(219): chr(s+0x3f),
        chr(220): chr(s+0x40),
        chr(221): chr(s+0x41),
        chr(222): chr(s+0x42),
        chr(223): chr(s+0x43),
        chr(224): chr(s+0x46),
        chr(225): chr(s+0x47),
        chr(226): chr(s+0x48),
        chr(227): chr(s+0x45),
        chr(228): chr(s+0x4a),
        chr(229): chr(s+0x4b),
        chr(230): chr(s+0x4c),
        chr(231): chr(s+0x49),
        chr(232): chr(s+0x4d),
        chr(233): chr(s+0x3c),
        chr(234): chr(s+0x64),
        chr(241): chr(s+0x66),
        chr(242): chr(s+0x67),
        chr(243): chr(s+0x68),
        chr(244): chr(s+0x69),
        chr(245): chr(s+0x6a),
        chr(246): chr(s+0x6b),
        chr(247): chr(s+0x6c),
        chr(248): chr(s+0x6d),
        chr(249): chr(s+0x6e),
        chr(250): chr(s+0x6f),
        '%c%c' % (161, 233): chr(s+0x50),
        '%c%c' % (166, 233): chr(s+0x0C),
        '%c%c' % (167, 233): chr(s+0x61),
        '%c%c' % (176, 233): chr(s+0x60),
        '%c%c' % (179, 233): chr(s+0x58),
        '%c%c' % (180, 233): chr(s+0x59),
        '%c%c' % (181, 233): chr(s+0x5a),
        '%c%c' % (186, 233): chr(s+0x5b),
        '%c%c' % (191, 233): chr(s+0x5c),
        '%c%c' % (192, 233): chr(s+0x5d),
        '%c%c' % (201, 233): chr(s+0x5e),
        '%c%c' % (219, 233): chr(s+0x62),
        '%c%c' % (220, 233): chr(s+0x63),
        '%c%c' % (223, 233): chr(s+0x44),
        '%c%c' % (234, 233): chr(s+0x64),
    }
    return ret

iscii_utf8_map = get_map(57002)


def iscii_utf8(i):
    buf = None
    get_next = [x[0] for x in iscii_utf8_map if len(x) == 2]
    for x in i:
        if x in get_next:
            buf = x
            continue
        if buf:
            if buf+x in iscii_utf8_map:
                yield iscii_utf8_map[buf+x]
            else:
                yield iscii_utf8_map[buf]
                yield iscii_utf8_map[x]
                buf = None
        else:
            if x in iscii_utf8_map:
                yield iscii_utf8_map[x]
            else:
                yield x
    return


def main():
    global iscii_utf8_map
    a = ['%c' % x for x in [65,' ', 165, 201, 209, 219, 233]]
    for x in range(57002, 57012):
        iscii_utf8_map = get_map(x)
        t = list(iscii_utf8(a))
        print(t)
        print(''.join([x for x in t]))

if __name__ == '__main__':
    main()
