/*
 * iscii2ud
 * 
 * A program to convert Indian-language text from ISCII to UTF-8
 * Unicode Devanagari.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#define MAXLINE 1000
#define N_NUKTA (sizeof nukta / sizeof nukta[0])

int main(int argc, char *argv[]);
void process(FILE *infile);
int get_line(unsigned char line[MAXLINE], int max, FILE *infile);
void utf8(unsigned short ch);

/* Array of ISCII codes that convert simply to Unicode */
unsigned char iscii[] = {
   0xa1,
   0xa2,
   0xa3,
   0xa4,
   0xa5,
   0xa6,
   0xa7,
   0xa8,
   0xa9,
   0xaa,
   0xab,
   0xac,
   0xad,
   0xae,
   0xaf,
   0xb0,
   0xb1,
   0xb2,
   0xb3,
   0xb4,
   0xb5,
   0xb6,
   0xb7,
   0xb8,
   0xb9,
   0xba,
   0xbb,
   0xbc,
   0xbd,
   0xbe,
   0xbf,
   0xc0,
   0xc1,
   0xc2,
   0xc3,
   0xc4,
   0xc5,
   0xc6,
   0xc7,
   0xc8,
   0xc9,
   0xca,
   0xcb,
   0xcc,
   0xcd,
   0xce,
   0xcf,
   0xd0,
   0xd1,
   0xd2,
   0xd3,
   0xd4,
   0xd5,
   0xd6,
   0xd7,
   0xd8,
   0xd9,		/* INV */
   0xda,
   0xdb,
   0xdc,
   0xdd,
   0xde,
   0xdf,
   0xe0,
   0xe1,
   0xe2,
   0xe3,
   0xe4,
   0xe5,
   0xe6,
   0xe7,
   0xe8,
   0xe9,		/* NUKTA */
   0xea,		/* 0xeb - 0xee not used; 0xef = ATR; 0xf0 = EXT */
   0xf1,
   0xf2,
   0xf3,
   0xf4,
   0xf5,
   0xf6,
   0xf7,
   0xf8,
   0xf9,
   0xfa			/* 0xfb - 0xff not used */
};

/* Unicode codes ordered in same sequence as ISCII ones */
unsigned short udev[] = {
   0x0901,
   0x0902,
   0x0903,
   0x0905,
   0x0906,
   0x0907,
   0x0908,
   0x0909,
   0x090a,
   0x090b,
   0x090e,
   0x090f,
   0x0910,
   0x090d,
   0x0912,
   0x0913,
   0x0914,
   0x0911,
   0x0915,
   0x0916,
   0x0917,
   0x0918,
   0x0919,
   0x091a,
   0x091b,
   0x091c,
   0x091d,
   0x091e,
   0x091f,
   0x0920,
   0x0921,
   0x0922,
   0x0923,
   0x0924,
   0x0925,
   0x0926,
   0x0927,
   0x0928,
   0x0929,
   0x092a,
   0x092b,
   0x092c,
   0x092d,
   0x092e,
   0x092f,
   0x095f,
   0x0930,
   0x0931,
   0x0932,
   0x0933,
   0x0934,
   0x0935,
   0x0936,
   0x0937,
   0x0938,
   0x0939,
   0x200d,		/* INV -> ZWJ */
   0x093e,
   0x093f,
   0x0940,
   0x0941,
   0x0942,
   0x0943,
   0x0946,
   0x0947,
   0x0948,
   0x0945,
   0x094a,
   0x094b,
   0x094c,
   0x0949,
   0x094d,
   0x093c,		/* NUKTA */
   0x0964,
   0x0966,
   0x0967,
   0x0968,
   0x0969,
   0x096a,
   0x096b,
   0x096c,
   0x096d,
   0x096e,
   0x096f
};

/* Array of ISCII characters whose value may be modified by a following
 * NUKTA
 */
unsigned char nukta[] = {
   0xb3,		/* ka */
   0xb4,		/* kha */
   0xb5,		/* ga */
   0xba,		/* ja */
   0xbf,		/* .da */
   0xc0,		/* .dha */
   0xc9,		/* pha */
   0xaa,		/* .r- */
   0xdf,		/* -.r */
   0xa6,		/* i- */
   0xdb,		/* -i */
   0xa7,		/* ii- */
   0xdc,		/* -ii */
   0xa1,		/* candrabindu */
   0xea			/* da.n.da */
};

/* Unicode codes ordered in same sequence as NUKTA ones */
unsigned short unukta[] = {
   0x0958,		/* qa */
   0x0959,		/* xa */
   0x095a,		/* .ga */
   0x095b,		/* za */
   0x095c,		/* Ra */
   0x095d,		/* Rha */
   0x095e,		/* fa */
   0x0960,		/* .R- */
   0x0944,		/* -.R */
   0x090c,		/* .l- */
   0x0962,		/* -.l */
   0x0961,		/* .L- */
   0x0963,		/* -.L */
   0x0950,		/* OM */
   0x093d		/* avagraha */
};

int main(int argc, char *argv[]) {
   char infname[128];
   FILE *infile;
   if (argc > 1) {
      strcpy(infname, argv[1]);
      if ((infile = fopen(infname, "r")) == NULL) {
	 fputs("\nUnable to open file\n", stderr);
	 exit(1);
      }
      process(infile);
      fclose(infile);
   }
   else process(stdin);
   exit(0);
}

/* process: do the job */
void process(FILE *infile) {
   int linenum = 0;
   unsigned short i, len;
   unsigned char line[MAXLINE], j, nhit;
   while ((len = get_line(line, MAXLINE, infile)) > 0) {
      ++linenum;
      for (i = 0; i < len; i++) {
	 if (line[i] < 0x80) {				/* ASCII */
	    fputc(line[i], stdout);
	    continue;
	 }
	 if ((line[i] < 0xa1) ||			/* Illegal */
	     ((line[i] > 0xea) && (line[i] < 0xef)) ||
	     (line[i] > 0xfa)) {
	    fprintf(stderr, "Ignoring character 0x%x at line %d\n",
		    line[i], linenum);
	    continue;
	 }
	 if (line[i] == 0xef) {				/* ATR */
	    ++i;
	    fprintf(stderr, "Use of ATR not supported at line %d\n",
		    linenum);
	    continue;
	 }
	 if (line[i] == 0xf0) {				/* EXT */
	    ++i;
	    fprintf(stderr, "Use of EXT not supported at line %d\n",
		    linenum);
	    continue;
	 }
	 nhit = 0;
	 for (j = 0; j < N_NUKTA; j++) {		/* NUKTA */
	    if (nukta[j] == line[i]) {
	       if (line[++i] == 0xe9) {
		  utf8(unukta[j]);
		  nhit++;
	       }
	       else --i;
	       break;
	    }
	 }
	 if (nhit) continue;
	 for (j = 0; ; j++) {				/* ISCII */
	    if (iscii[j] == line[i]) {
	       utf8(udev[j]);
	       break;
	    }
	 }
      }
   }
}

/* get_line: read a line, return length */
int get_line(unsigned char line[MAXLINE], int max, FILE *infile) {
   if (fgets(line, max, infile) == NULL) return 0;
   else return strlen(line);
}

/* utf8: output a UTF-8 character */
void utf8(unsigned short ch) {
   if (ch > 0x7FF) {
      fputc((unsigned char)(((ch >> 12) & 0xF) | 0xE0), stdout);
      fputc((unsigned char)(((ch >> 6) & 0x3F) | 0x80), stdout);
      fputc((unsigned char)((ch & 0x3F) | 0x80), stdout);
   }
   else {
      if (ch > 0x7F) {
	 fputc((unsigned char)(((ch >> 6) & 0x1F) | 0xC0), stdout);
	 fputc((unsigned char)((ch & 0x3F) | 0x80), stdout);
      }
      else {
	 fputc((unsigned char)ch, stdout);
      }
   }
}
