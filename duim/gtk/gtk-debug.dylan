Module:       gtk-duim
Synopsis:     GTK debugging functionality
Author:       Andy Armstrong, Scott McKay
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define function dbg (message, #rest args)
  apply(format-out, concatenate(message, "\n"), args);
end;

//*debug-duim-function* := dbg;