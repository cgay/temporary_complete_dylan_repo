Module:       dylan-user
Synopsis:     Example using windows resources in DUIM
Author:       Roman Budzianowski, Andy Armstrong, Scott McKay
Copyright:    Original Code is Copyright (c) 1997-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library duim-resource-example
  use functional-dylan;
  use io;
  use system;
  use win32-user;		//--- for debugging
  use win32-resources;		//--- for debugging

  use duim;
end library duim-resource-example;

define module duim-resource-example
  use functional-dylan;
  use format;
  use format-out;
  use operating-system;
  use win32-user;		//--- for debugging
  use win32-resources;		//--- for debugging

  use duim-internals,
    exclude: { position };

  export <example-window>,
	 describe-resources;
end module duim-resource-example;
