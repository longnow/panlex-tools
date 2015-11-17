<?php

// +----------------------------------------------------------------------+
// | iscii2utf8 1.0                                                       |
// +----------------------------------------------------------------------+
// | Author : Sunish K Kurup (sunish_mv@rediffmail.com)                   |
// | Date    : 02/04/2003                                                     |
// +----------------------------------------------------------------------+
//
// ISCII to unicode(utf8) converter for Devnagiri Hindi font
//

  class UnicodeManager {

      var $map;
      var $mapIscii;

      function __construct() {

          $this->map = array (
                   "a0" =>  '63'  ,
                 "a1" => '2305' ,
                 "a2" => '2306' ,
                 "a3" => '2307' ,
                 "a4" => '2309' ,
                 "a5" => '2310' ,
                 "a6" => '2311' ,
                 "a7" => '2312' ,
                 "a8" => '2313' ,
                 "a9" => '2314' ,
                 "aa" => '2315' ,
                 "ab" => '2318' ,
                 "ac" => '2319' ,
                 "ad" => '2320' ,
                 "ae" => '2317' ,
                 "af" => '2322' ,
                 "b0" => '2323' ,
                 "b1" => '2324' ,
                 "b2" => '2321' ,
                 "b3" => '2325' ,
                 "b4" => '2326' ,
                 "b5" => '2327' ,
                 "b6" => '2328' ,
                 "b7" => '2329' ,
                 "b8" => '2330' ,
                 "b9" => '2331' ,
                 "ba" => '2332' ,
                 "bb" => '2333' ,
                 "bc" => '2334' ,
                 "bd" => '2335' ,
                 "be" => '2336' ,
                 "bf" => '2337' ,
                 "c0" => '2338' ,
                 "c1" => '2339' ,
                 "c2" => '2340' ,
                 "c3" => '2341' ,
                 "c4" => '2342' ,
                 "c5" => '2343' ,
                 "c6" => '2344' ,
                 "c7" => '2345' ,
                 "c8" => '2346' ,
                 "c9" => '2347' ,
                 "ca" => '2348' ,
                 "cb" => '2349' ,
                 "cc" => '2350' ,
                 "cd" => '2351' ,
                 "ce" => '2399' ,
                 "cf" => '2352' ,
                 "d0" => '2353' ,
                 "d1" => '2354' ,
                 "d2" => '2355' ,
                 "d3" => '2356' ,
                 "d4" => '2357' ,
                 "d5" => '2358' ,
                 "d6" => '2359' ,
                 "d7" => '2360' ,
                 "d8" => '2361' ,
                 "d9" =>  '63'  ,
                 "da" => '2366' ,
                 "db" => '2367' ,
                 "dc" => '2368' ,
                 "dd" => '2369' ,
                 "de" => '2370' ,
                 "df" => '2371' ,
                 "e0" => '2374' ,
                 "e1" => '2375' ,
                 "e2" => '2376' ,
                 "e3" => '2373' ,
                 "e4" => '2378' ,
                 "e5" => '2379' ,
                 "e6" => '2380' ,
                 "e7" => '2377' ,
                 "e8" => '2381' ,
                 "e9" =>  '63'  ,
                 "ea" => '2404' ,
                 "eb" =>  '63'  ,
                 "ec" =>  '63'  ,
                 "ed" =>  '63'  ,
                 "ee" =>  '63'  ,
                 "ef" =>  '63'  ,
                 "f0" =>  '63'  ,
                 "f1" => '2406' ,
                 "f2" => '2407' ,
                 "f3" => '2408' ,
                 "f4" => '2409' ,
                 "f5" => '2410' ,
                 "f6" => '2411' ,
                 "f7" => '2412' ,
                 "f8" => '2413' ,
                 "f9" => '2414' ,
                 "fa" => '2415' ,
                 "fb" =>  '63'  ,
                 "fc" =>  '63'  ,
                 "fd" =>  '63'  ,
                 "fe" =>  '63'  ,
                 "ff" =>  '63'  );
                 
            $this->mapIscii = array (
                 2305 => '161',
                 2306 => '162',
                 2307 => '163',
                 2309 => '164',
                 2310 => '165',
                 2311 => '166',
                 2312 => '167',
                 2313 => '168',
                 2314 => '169',
                 2315 => '170',
                 2318 => '171',
                 2319 => '172',
                 2320 => '173',
                 2317 => '174',
                 2322 => '175',
                 2323 => '176',
                 2324 => '177',
                 2321 => '178',
                 2325 => '179',
                 2326 => '180',
                 2327 => '181',
                 2328 => '182',
                 2329 => '183',
                 2330 => '184',
                 2331 => '185',
                 2332 => '186',
                 2333 => '187',
                 2334 => '188',
                 2335 => '189',
                 2336 => '190',
                 2337 => '191',
                 2338 => '192',
                 2339 => '193',
                 2340 => '194',
                 2341 => '195',
                 2342 => '196',
                 2343 => '197',
                 2344 => '198',
                 2345 => '199',
                 2346 => '200',
                 2347 => '201',
                 2348 => '202',
                 2349 => '203',
                 2350 => '204',
                 2351 => '205',
                 2399 => '206',
                 2352 => '207',
                 2353 => '208',
                 2354 => '209',
                 2355 => '210',
                 2356 => '211',
                 2357 => '212',
                 2358 => '213',
                 2359 => '214',
                 2360 => '215',
                 2361 => '216',
                 2366 => '218',
                 2367 => '219',
                 2368 => '220',
                 2369 => '221',
                 2370 => '222',
                 2371 => '223',
                 2374 => '224',
                 2375 => '225',
                 2376 => '226',
                 2373 => '227',
                 2378 => '228',
                 2379 => '229',
                 2380 => '230',
                 2377 => '231',
                 2381 => '232',
                 2404 => '234',
                 2406 => '241',
                 2407 => '242',
                 2408 => '243',
                 2409 => '244',
                 2410 => '245',
                 2411 => '246',
                 2412 => '247',
                 2413 => '248',
                 2414 => '249',
                 2415 => '250');
                 
                 
        }

        function code2utf($num){

             //Returns the utf string corresponding to the unicode value
             //courtesy - romans@void.lv

             if($num<128)return chr($num);
             if($num<1024)return chr(($num>>6)+192).chr(($num&63)+128);
             if($num<32768)return chr(($num>>12)+224).chr((($num>>6)&63)+128).chr(($num&63)+128);
             if($num<2097152)return chr($num>>18+240).chr((($num>>12)&63)+128).chr(($num>>6)&63+128). chr($num&63+128);
             return '';

        }


        function convert2utf($iscii) {
            
            $str = "";
            for($i = 0; $i<strlen($iscii); $i++) {

                $c = dechex(ord(substr($iscii,$i,1)));
                if (isset($this->map[$c] )) {
                    $s = $this->code2utf($this->map[$c]);
                    $str .= ($s == "?")?"":$s;
                    }
                else {
                   $str .= substr($iscii,$i,1);
                   }

            }

            return $str;
     }
        
        
     function utf8_to_unicode( $str ) {
        
        $unicode = array();        
        $values = array();
        $lookingFor = 1;
        
        for ($i = 0; $i < strlen( $str ); $i++ ) {

            $thisValue = ord( $str[ $i ] );
            
            if ( $thisValue < 128 ) $unicode[] = $thisValue;
            else {
            
                if ( count( $values ) == 0 ) $lookingFor = ( $thisValue < 224 ) ? 2 : 3;
                
                $values[] = $thisValue;
                
                if ( count( $values ) == $lookingFor ) {
            
                    $number = ( $lookingFor == 3 ) ?
                        ( ( $values[0] % 16 ) * 4096 ) + ( ( $values[1] % 64 ) * 64 ) + ( $values[2] % 64 ):
                    	( ( $values[0] % 32 ) * 64 ) + ( $values[1] % 64 );
                        
                    $unicode[] = $number;
                    $values = array();
                    $lookingFor = 1;
            
                } 
            
            } 
            
        } 

        return $unicode;
    
    } 
    
    function convert2iscii($str /*UTF Encoded*/){
    	
    	$iscii = "";        
        $values = array();
        $lookingFor = 1;
        
        for ($i = 0; $i < strlen( $str ); $i++ ) {

            $thisValue = ord( $str[ $i ] );
            
            if ( $thisValue < 128 ) $iscii .= chr($thisValue);
            else {
            
                if ( count( $values ) == 0 ) $lookingFor = ( $thisValue < 224 ) ? 2 : 3;
                
                $values[] = $thisValue;
                
                if ( count( $values ) == $lookingFor ) {
            
                    $number = ( $lookingFor == 3 ) ?
                        ( ( $values[0] % 16 ) * 4096 ) + ( ( $values[1] % 64 ) * 64 ) + ( $values[2] % 64 ):
                    	( ( $values[0] % 32 ) * 64 ) + ( $values[1] % 64 );
                        
                    $iscii .= chr($this->mapIscii[$number]);
                    $values = array();
                    $lookingFor = 1;
            
                } 
            
            } 
            
        } 

        return $iscii ;
    	
    }
    
  }

?>