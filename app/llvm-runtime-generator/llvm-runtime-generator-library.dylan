Module: dylan-user
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              Additional code is Copyright 2010 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library llvm-runtime-generator
  use common-dylan;
  use io;
  use system;
  use llvm;
  use dfmc-core;
  use dfmc-management;
  use dfmc-back-end;
  use dfmc-llvm-back-end;
end library;

define module llvm-runtime-generator
  use common-dylan, exclude: { format-to-string };
  use operating-system;
  use format;
  use standard-io;
  use llvm;
  use llvm-builder;
  use dfmc-core;
  use dfmc-imports;
  use dfmc-management;
  use dfmc-back-end;
  use dfmc-llvm-back-end;
end module;
