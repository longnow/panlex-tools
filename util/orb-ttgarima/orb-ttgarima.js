var array_one = new Array(

    //Sanyuktaaxar
    'Ø', '୍ତ',
    '³', 'ନ୍ଦ',
    '¼»', 'ଙ୍କ',
    'û', '୍ଲ',
    'õ', '୍ମ',
    'î', '୍ଯ',
    'ÑÂ', 'ଳ୍ପ',
    '\´', 'ନ୍ଧ',
    '÷', '୍ନ',
    'ó', '୍ବ',
    //'×'   ,  '୍ଥ' ,
    'ñ', '୍ର',
    'ô', '୍ବ',
    'ÈÂ', 'ଜ୍ଜ',
    '®×', 'ଚ୍ଛ',
    '®', 'ଚ୍ଚ',
    'ÐÂ', '୍ତ୍ର',
    '±', 'ତ୍ତ',
    'Õ', '୍କ',
    'Ö', '୍ଠ',
    'ö', '୍୍',
    'ÉÂ', 'ମ୍ପ',

    //'Ł'   ,  'ଃ' ,
    'Þ', 'ଆ',  //aa
    '', 'ଅ',   //a
    '\‚', 'ଇ', // i
    //'§'   ,  'ଈ' , //ii
    '\„', 'ଉ', // u
    //'©'   ,  'ଊ' , //uu
    '†', 'ଋ',  // Ri
    'ˆ‰', 'ଐ', // ai
    'ˆ', 'ଏ', // e
    'Š‰', 'ଔ', // au
    'Š', 'ଓ', // o

    '–Í', 'ଡ଼',  //'ड़' ,
    '—Í', 'ଢ଼',  //'ढ़' ,

    '¤©', 'କ୍ଷ',
    'Ç©', 'ଷ',
    '‹', 'କ',
    'OE', 'ଖ',
    'Œ', 'ଖ',
    '', 'ଗ',
    'Ô', 'ଘ',
    '»', 'ଙ',
    '×', 'ଛ',
    '', 'ଚ',
    '\‘', 'ଜ',
    '\’', 'ଝ',
    '\“', 'ଞ',
    '\”', 'ଟ',
    '•', 'ଠ',
    '–', 'ଡ',
    '—', 'ଢ',
    '\˜', 'ଣ',
    '™', 'ତ',
    'š', 'ଥ',
    '\›', 'ଦ',
    'oe', 'ଧ',
    '', 'ନ',
    'Ç', 'ପ',
    'Ÿ', 'ଫ',
    '¡', 'ବ',
    '¢', 'ଭ',
    '£', 'ମ',
    '¤ý', 'ୟ',  // ya
    '¤', 'ଯ',  //ja
    '¥', 'ର',
    '¬', 'ଲ',
    '¦', 'ଳ',  // LL
    //'Ô'   ,  'ବ' ,
    '¨', 'ଶ',
    'ª', 'ସ',
    '\«', 'ହ',
    '²', 'ଜ୍ଞ',

    'Í', '଼',  //Nukta
    'ì', '୍',  // halant
    'Þ', 'ା',
    'ß', 'ି',
    'à', 'ୀ',
    'Ú', 'ୁ',
    'Ü', 'ୁ',
    'Û', 'ୂ',

    'ê', 'ଁ',
    'ä', 'ଂ',
    'ï', 'ୃ',

    // '\xEA'  ,         '।' ,   //Full stop or DaNDaa

    '0', '୦',  //Oriya zero
    '1', '୧',
    '2', '୨',
    '3', '୩',
    '4', '୪',
    '5', '୫',
    '6', '୬',
    '7', '୭',
    '8', '୮',
    '9', '୯'
);

var array_one_length = array_one.length;

module.exports = Convert_Font_01;

function Convert_Font_01(input) {

    var modified_substring = input;

    //****************************************************************************************
    //  Break the long text into small bunches of max. max_text_size  characters each.
    //****************************************************************************************
    var text_size = input.length;

    var processed_text = '';  //blank

    var sthiti1 = 0;
    var sthiti2 = 0;
    var chale_chalo = 1;
    var max_text_size = 6000;

    var ret;

    while (chale_chalo == 1) {
        sthiti1 = sthiti2;

        if (sthiti2 < (text_size - max_text_size)) {
            sthiti2 += max_text_size;
            //while (document.getElementById("legacy_text").value.charAt ( sthiti2 ) != ' ') {sthiti2--;}
        }
        else {
            sthiti2 = text_size; chale_chalo = 0;
        }

        modified_substring = input.substring(sthiti1, sthiti2);

        Replace_Symbols();

        var processed_text = processed_text + modified_substring;

        //  Breaking part code over

        ret = processed_text;

    }

    return ret.trim();

    //--------------------------------------------------

    function Replace_Symbols() {

        if (modified_substring != "")  // if string to be converted is non-blank then no need of any processing.
        {
            for (input_symbol_idx = 0; input_symbol_idx < array_one_length - 1 ; input_symbol_idx = input_symbol_idx + 2) {
                indx = 0;  // index of the symbol being searched for replacement

                while (indx != -1) //whie-00
                {
                    modified_substring = modified_substring.replace(array_one[input_symbol_idx], array_one[input_symbol_idx + 1]);
                    indx = modified_substring.indexOf(array_one[input_symbol_idx]);

                } // end of while-00 loop
            } // end of for loop



            //-----------------------------------------------

            // code for regularizing  'e', 'o' and 'au'  maatraa

            position_of_e = modified_substring.indexOf("á")

            while (position_of_e != -1)  //while-03
            {
                var character_next_to_i = modified_substring.charAt(position_of_e + 1);
                var character_to_be_replaced = "á" + character_next_to_i;
                modified_substring = modified_substring.replace(character_to_be_replaced, character_next_to_i + "େ");

                position_of_e = modified_substring.search(/á/, position_of_e + 1) // search for i ahead of the current position.

            } // end of while-03 loop

            modified_substring = modified_substring.replace(/ୋâ/g, "\u0B4C");
            modified_substring = modified_substring.replace(/ୋ/g, "\u0B4B");
            modified_substring = modified_substring.replace(/େâ/g, "\u0B48");

            //************************************************
            // Eliminating reph "í" and putting 'half - r' at proper position for this.
            set_of_matras = "ଁଂଃ଼ଽାିୀୁୂୃେୈୋୌ";

            modified_substring = '  ' + modified_substring;  // to avoid error due to search index becoming negative.
            var position_of_R = modified_substring.indexOf("í")

            while (position_of_R > 0)  // while-04
            {
                probable_position_of_half_r = position_of_R - 1;
                var charecter_at_probable_position_of_half_r = modified_substring.charAt(probable_position_of_half_r)

                // trying to find non-maatra position left to current O (ie, half -r).

                while (set_of_matras.match(charecter_at_probable_position_of_half_r) != null)  // while-05

                {
                    probable_position_of_half_r = probable_position_of_half_r - 1;
                    charecter_at_probable_position_of_half_r = modified_substring.charAt(probable_position_of_half_r);

                } // end of while-05

                if (modified_substring.charAt(probable_position_of_half_r - 1) == '୍') {
                    probable_position_of_half_r = probable_position_of_half_r - 2;
                    if (modified_substring.charAt(probable_position_of_half_r - 1) == '୍')
                        probable_position_of_half_r = probable_position_of_half_r - 2;
                }

                charecter_to_be_replaced = modified_substring.substr(probable_position_of_half_r, (position_of_R - probable_position_of_half_r));
                new_replacement_string = "ର୍" + charecter_to_be_replaced;
                charecter_to_be_replaced = charecter_to_be_replaced + "í";
                modified_substring = modified_substring.replace(charecter_to_be_replaced, new_replacement_string);
                position_of_R = modified_substring.indexOf("í");

            } // end of while-04

            //************************************************
            // Eliminating "þ" and putting 'half - t' (like in utkala) at proper position for this.

            set_of_matras = "ଁଂଃ଼ଽାିୀୁୂୃେୈୋୌ";  // all the maatraas

            modified_substring = '  ' + modified_substring;  // to avoid error due to search index becoming negative.
            var position_of_t = modified_substring.indexOf("þ")

            while (position_of_t > 0)  // while-04
            {
                probable_position_of_half_t = position_of_t - 1;
                var charecter_at_probable_position_of_half_t = modified_substring.charAt(probable_position_of_half_t)

                // trying to find non-maatra position left to current O (ie, half -r).

                while (set_of_matras.match(charecter_at_probable_position_of_half_t) != null)  // while-05

                {
                    probable_position_of_half_t = probable_position_of_half_t - 1;
                    charecter_at_probable_position_of_half_t = modified_substring.charAt(probable_position_of_half_t);

                } // end of while-05

                if (modified_substring.charAt(probable_position_of_half_t - 1) == '୍') {
                    probable_position_of_half_t = probable_position_of_half_t - 2;
                    if (modified_substring.charAt(probable_position_of_half_t - 1) == '୍')
                        probable_position_of_half_t = probable_position_of_half_t - 2;
                }

                charecter_to_be_replaced = modified_substring.substr(probable_position_of_half_t, (position_of_t - probable_position_of_half_t));
                new_replacement_string = "ତ୍" + charecter_to_be_replaced;
                charecter_to_be_replaced = charecter_to_be_replaced + "þ";
                modified_substring = modified_substring.replace(charecter_to_be_replaced, new_replacement_string);
                position_of_t = modified_substring.indexOf("þ");

            } // end of while-04

        } //end of IF  statement  meant to  supress processing of  blank  string.

    } // end of the function  Replace_Symbols

} // end of BN_TT_Durga-to-Devanagari function
