Module:    dylan-user
Synopsis:  Dylan compiler
Author:    Roman Budzianowski
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library pentium-dw
  use functional-dylan;
  use system;
  use io;

  use release-info;

  use memory-manager;
  use dood;
  use dispatch-profiler;
  use projects;
  use registry-projects;
  use user-projects;
  use dfmc-browser-support;
  
  use dfmc-common;

  use source-records;
  use file-source-records;

  // Load a back-end
  use dfmc-namespace;
  use dfmc-optimization;
  use dfmc-debug-back-end;
  use dfmc-pentium-file-compiler;

  // Load the tool interfaces
  use motley;
  use tool-scepter;

  use dfmc-shell;

  export dw;

end library pentium-dw;
