Module:    xml-parser-test
Synopsis:  Tests for the XML converter.
Author:    Dr. Matthias H�lzl
Copyright: (C) 2005, Dr. Matthias H�lzl.  All rights reserved.

define suite xml-parser-suite ()
  suite namespace-suite;
  suite macros-suite;
end suite xml-parser-suite;

define method main () => ()
  perform-suite(xml-parser-suite);
//  format-out("Done.\n");
end method main;

begin
  main();
end;
