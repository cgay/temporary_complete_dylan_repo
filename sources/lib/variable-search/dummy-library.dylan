Module: dylan-user
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// Also requires the Functional Developer extension debug-name.

define library variable-search
  use dylan;
  export
    variable-search;
end library;

define module variable-search
  use dylan;
  export
    locate-variable, variable-value;
end module;  

// eof