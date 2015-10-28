import sys
import chardet
import codecs


class Transcode:
   """This class is used to detect the encoding of files, and transcode them to utf-8."""
   #___________________________________________________________________________

   DETECTIONCONFIDENCE = 0.8
   OUTCODING = "utf-8"

   def __init__(self, infile="", outfile="", transcode=True, debug=False):
       self.initparams()
       if infile: self.transcode(infile,outfile,transcode,debug)


   def initparams(self):
       self._incoding = ""

   #___________________________________________________________________________

   def incoding(self, encoding=""):
       if encoding:
           self._incoding = encoding
       return self._incoding


   #___________________________________________________________________________

   def transcode(self, infile="", outfile="", transcode=True, debug=False):
       if infile:
           try:
               sys.stderr.write("Attempting to detect character encoding ...\n")
               encoding = chardet.detect(open(infile).read())
               encoding["confidence"] >= self.DETECTIONCONFIDENCE
               sys.stderr.write("Character encoding predicted to be: {0} (confidence = {1})\n".format(encoding["encoding"],encoding["confidence"]))
               self.incoding(encoding["encoding"])
               if transcode and outfile:
                   sys.stderr.write("Transcoding '{0}', and saving the output in '{1}'\n".format(infile,outfile))
                   infp = codecs.open(infile, "r", self.incoding())
                   outfp = codecs.open(outfile, "w", self.OUTCODING)
                   outfp.write(infp.read())
                   while True:
                       block = infp.read()
                       if not block: break
                       outfp.write(block)
                   infp.close()
                   outfp.close()
           except IOError as (errno, strerror):
               sys.stderr.write("I/O error({0}): {1}\n".format(errno, strerror))
           except:
               sys.stderr.write("Unexpected error: ", sys.exc_info()[0])
               raise


   #___________________________________________________________________________

   def usage(self, err):
       sys.stderr.write("""
ERROR: {0}

USAGE:

transcode.py

-i,--in INFILE    parse the (single) file named INFILE [REQUIRED]

-o,--out OUTFILE  transcode INFILE and save the output in OUTFILE [ASSUMES -t MODE]

-t,--transcode    use the best-guess character encoding, and transcode to utf-8

""".format(err))



   #___________________________________________________________________________

if __name__ == "__main__":
   t = Transcode()
   import getopt
   try:                                
       opts, args = getopt.getopt(sys.argv[1:], "i:o:t", ["in=", "out=", "transcode"])
       infile = outfile = ""
       do_transcode = False
       for flag, arg in opts:
           if flag == "-i" or flag == "--in":
               if not arg: raise(getopt.GetoptError, "no input file given for {0} option".format(flag))
               elif infile: raise(getopt.GetoptError, "multiple input files given")
               infile = arg
           elif flag == "-o" or flag == "--out":
               if not arg: raise(getopt.GetoptError, "no output file given for {0} option".format(flag))
               elif outfile: raise(getopt.GetoptError, "multiple output files given")
               outfile = arg
               do_transcode = True
           elif flag == "-t" or flag == "--transcode":
               if arg: raise(getopt.GetoptError, "option given for {0} option".format(flag))
               do_transcode = True
       if not infile: raise(getopt.GetoptError), "no input file provided"
       elif outfile and not do_transcode: raise(getopt.GetoptError), "not transcoding, but output file provided"
       t.transcode(infile,outfile,do_transcode)
   except getopt.GetoptError, err:
       t.usage(err)
       sys.exit(2)                     
