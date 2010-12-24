Module: dfmc-llvm-back-end
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              Additional code is Copyright 2009-2010 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Operating System


define side-effecting stateless dynamic-extent &c-primitive-descriptor primitive-exit-application
    (code :: <raw-integer>) => ();

define side-effecting stateless dynamic-extent &c-primitive-descriptor primitive-start-timer () => ();

define side-effecting stateless dynamic-extent &unimplemented-primitive-descriptor primitive-stop-timer
    () => (time :: <simple-object-vector>);
  //---*** Fill this in...
end;


/// Support for keyboard-break handling

define side-effect-free &c-primitive-descriptor primitive-keyboard-interrupt-signaled
  () => (interrupt? :: <raw-boolean>);

define side-effecting &c-primitive-descriptor primitive-keyboard-interrupt-signaled-setter
  (interrupt? :: <raw-boolean>)  => ();

define side-effect-free &c-primitive-descriptor primitive-keyboard-interrupt-polling ()
  => (interrupt-polling? :: <raw-boolean>);

define side-effecting &c-primitive-descriptor primitive-keyboard-interrupt-polling-setter
  (interrupt-polling? :: <raw-boolean>) => ();

define side-effect-free &c-primitive-descriptor primitive-keyboard-interrupt-polling-thread (hThread :: <raw-pointer>)
  => (interrupt-polling? :: <raw-boolean>);

define side-effecting &c-primitive-descriptor primitive-keyboard-interrupt-polling-thread-setter
  (interrupt-polling? :: <raw-boolean>, hThread :: <raw-pointer>) => ();


/// (Win32) DLL Support

// FIXME these both need to be per-DLL/local

// module_hInstance holds the module handle for Dylan DLLs
define runtime-variable module-hInstance :: <raw-machine-word>
  = make-raw-literal(as(<machine-word>, 0));

define side-effecting &runtime-primitive-descriptor primitive-runtime-module-handle
    () => (handle :: <machine-word>);
  let raw-handle
    = ins--load(be, module-hInstance-descriptor.runtime-variable-global);
  call-primitive(be, primitive-wrap-machine-word-descriptor, raw-handle)
end;
