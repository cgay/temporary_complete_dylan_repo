Module:    functional-dylan-internals
Author:    Jonathan Bachrach, Andy Armstrong
Copyright: Copyright (c) 1996-2000 Functional Objects, Inc. All rights reserved.

//---*** Remove these when we are sure nobody is using them
define inline constant not-found  = method () $unfound end;
define inline constant not-found? = method (x) x == $unfound; end;


/// Support for breakpoints on class allocation

define function set-class-breakpoint
    (class :: <class>, #key count) => ()
  primitive-set-class-breakpoint(class, count | 1);
end function;

define function clear-class-breakpoint(class :: <class>) => ()
  primitive-clear-class-breakpoint(class);
end function;

define function clear-class-breakpoints() => ()
  primitive-clear-class-breakpoint(integer-as-raw(0));
end function;

define constant $breaks-buffer-max = 4096;
define thread variable dylan-breaks-string-buffer :: <byte-string> = "";

define function display-class-breakpoints() => ()
  if (dylan-breaks-string-buffer.empty?)
    dylan-breaks-string-buffer := make(<byte-string>, size: $breaks-buffer-max, fill: '\0');
  end if;
  let actual-buffer-size :: <integer> =
    raw-as-integer(primitive-display-class-breakpoints(primitive-string-as-raw(dylan-breaks-string-buffer)));
  write-console(dylan-breaks-string-buffer, end: actual-buffer-size);
end function;

