Module:       Dylan-User
Synopsis:     Standalone wrapper for DUIM-Deuce
Author:       Scott McKay
Copyright:    Original Code is Copyright (c) 1996-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library standalone-deuce
  use functional-dylan;
  use threads;
  use collections;
  use io;
  use system;

  use duim;
  use deuce;
  use duim-deuce;

  export standalone-deuce,
	 standalone-deuce-internals;
end library standalone-deuce;
