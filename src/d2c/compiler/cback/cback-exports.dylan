module: dylan-user
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/cback/cback-exports.dylan,v 1.16 1996/11/04 19:18:09 ram Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

define library compiler-cback
  use Dylan;
  use stream-extensions;
  use compiler-base;
  use compiler-front;
  use compiler-convert;
  export cback;
  export heap;
end library;


define module stack-analysis
  use common;
  use utils;
  use flow;
  use front;
  use ctype;
  use signature-interface;
  use definitions;
  use compile-time-functions;

  export
    analyze-stack-usage;
end;


define module cback
  use system;
  
  use indenting-streams;
  use c-representation;
  use classes;
  use common;
  use compile-time-functions;
  use compile-time-values;
  use target-environment,
    import: {*current-target*, target-integer-length};
  use ctype;
  use definitions;
  // use define-functions;
  use function-definitions;
  // use define-constants-and-variables;
  use variable-definitions;
  use define-classes;
  // use forward-defn-classes;
  use flow;
  use front;
  use names;
  use od-format;
  use primitives;
  use representation;
  use signature-interface;
  use stack-analysis;
  // use top-level-expressions;
  use top-level-forms;
  use utils;
  use variables;
  use source;
  // use cheese;

  export
    <unit-state>, unit-prefix, unit-init-roots, unit-eagerly-reference,
    <root>, root-name, root-init-value, root-comment,
    <file-state>, 
    emit-prologue, emit-tlf-gunk, emit-component,
    get-info-for, const-info-heap-labels, const-info-heap-labels-setter,
    const-info-dumped?, const-info-dumped?-setter,
    entry-point-c-name, *emit-all-function-objects?*;
end;


define module heap
  use common;
  use utils;
  use errors;
  use names;
  use signature-interface;
  use compile-time-values;
  use variables;
  use representation;
  use c-representation;
  use ctype;
  use classes;
  use compile-time-functions;
  use definitions;
  // use define-functions;
  use function-definitions;
  // use define-classes;
  use cback;
  use od-format;
  use target-environment;

  export
    build-global-heap, build-local-heap;
end;

