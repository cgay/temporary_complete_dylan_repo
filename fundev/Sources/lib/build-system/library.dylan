Module:       dylan-user
Synopsis:     A build-system for Dylan Applications in Dylan
Author:       Nosa Omo, Peter S. Housel
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library build-system
  use functional-dylan;
  use io;
  use system;
  use file-source-records;
  use release-info;
  use dfmc-mangling;
  use jam;

  export
    build-system;
end library build-system;

define module build-system
  use functional-dylan;
  use dylan-primitives;
  use threads;
  use operating-system;
  use date;
  use file-system;
  use streams-internals;
  use standard-io;
  use format-out;
  use format;
  use jam;
  use file-source-records;
  use locators;
  use settings;
  use release-info;
  use dfmc-mangling;

  export
    build-system,

    default-build-script,
    default-build-script-setter,

    merged-project-name,
    merged-project-libraries,
    
    //$personal-lib,
    $personal-bin,
    //$system-lib,
    //$system-bin,
    //$system-build,
    //$release-root,
    //$override-default-linker,
    //$override-default-dll-policy,
    //$dylan-executable-name,
    //$dylan-support,

    system-install-path,
    system-registry-path,
    system-release-path,
    system-build-path,
    user-registry-path,
    user-projects-path,
    user-projects-path-setter,
    user-install-path,
    user-build-path;
end module build-system;
