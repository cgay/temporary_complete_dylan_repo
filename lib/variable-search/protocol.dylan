Module: variable-search
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define generic locate-variable (object)
  => (variable-encoding, module-encoding, library-encoding);

define generic variable-value 
    (variable-encoding, module-encoding, library-encoding, #key)
  => (object);
