Module:       dylan-user
Author:       Andy Armstrong
Synopsis:     DUIM interface builder
Copyright:    Original Code is Copyright (c) 1998-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define module interface-builder
  use functional-dylan;
  use threads;
  use streams;
  use format;

  use duim;

  export <interface-builder>,
         start-interface-builder;
end module interface-builder;
