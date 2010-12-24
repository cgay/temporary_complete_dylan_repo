Module: dfmc-llvm-back-end
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              Additional code is Copyright 2009-2010 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define abstract class <llvm-back-end> (<back-end>, <llvm-builder>)
  // Predefined LLVM types
  constant slot %type-table :: <mutable-explicit-key-collection>
    = make(<string-table>);

  // LLVM type for each defined <&raw-type> instance
  constant slot %raw-type-table :: <object-table>
    = make(<object-table>);

  // Cache of <llvm-pointer-type> objects, keyed by pointee
  constant slot %pointer-to-table :: <object-table>
    = make(<object-table>, weak: #"value");

  // Cache of direct objects
  constant slot %direct-object-table :: <object-table>
    = make(<object-table>, weak: #"value");

  // Cache of (integral, word-sized) raw objects
  constant slot %raw-object-table :: <object-table>
    = make(<object-table>, weak: #"value");

  // Cache of object references
  constant slot %reference-table :: <string-table>
    = make(<string-table>, weak: #"value");

  // Computed <llvm-function> objects for runtime and C primitives,
  // keyed by <llvm-primitive-descriptor> object reference
  constant slot %primitive-function-table :: <object-table>
    = make(<object-table>);

  // Precomputed byte character constants
  constant slot %byte-character-constants :: <simple-object-vector>
    = make(<simple-object-vector>, size: 256);

  // Value import function
  inherited slot llvm-builder-value-function,
    init-value: llvm-back-end-value-function;
end;

define generic llvm-back-end-target-triple
    (back-end :: <llvm-back-end>) => (triple :: <string>);

define generic llvm-back-end-data-layout
    (back-end :: <llvm-back-end>) => (layout :: <string>);

define sealed method initialize
    (back-end :: <llvm-back-end>, #key, #all-keys) => ()
  next-method();
  initialize-type-table(back-end);
  initialize-raw-type-table(back-end);

  // Create canonical instances of the 256 i8 constants
  for (i from 0 below 256)
    back-end.%byte-character-constants[i]
      := make(<llvm-integer-constant>, type: $llvm-i8-type, integer: i);
  end for;
end method;

define thread variable *loose-mode?* = #f;
define thread variable *interactive-mode?* = #f;

define method llvm-retract-cached (back-end :: <llvm-back-end>) => ()
  remove-all-keys!(back-end.%pointer-to-table);
  remove-all-keys!(back-end.%direct-object-table);
  remove-all-keys!(back-end.%raw-object-table);
  remove-all-keys!(back-end.%reference-table);
end method;


/// Value import support

define method llvm-back-end-value-function
    (builder :: <llvm-back-end>, value :: <llvm-value>)
 => (result :: <llvm-value>);
  value
end method;

// Automatically declare referenced global values in the current module
define method llvm-back-end-value-function
    (builder :: <llvm-back-end>, value :: <llvm-global-value>)
 => (result :: <llvm-value>);
  llvm-builder-declare-global(builder, value.llvm-global-name, value)
end method;

define method llvm-back-end-value-function
    (back-end :: <llvm-back-end>, value :: <abstract-integer>)
 => (result :: <llvm-value>);
  element(back-end.%raw-object-table, value, default: #f)
    | begin
        let iWord-type = back-end.%type-table["iWord"];
        let constant
          = make(<llvm-integer-constant>, type: iWord-type, integer: value);
        element(back-end.%raw-object-table, value) := constant;
        constant
      end
end method;

define method llvm-back-end-value-function
    (back-end :: <llvm-back-end>, value :: <single-float>)
 => (result :: <llvm-value>);
  make(<llvm-float-constant>, type: $llvm-float-type, float: value)
end method;

define method llvm-back-end-value-function
    (back-end :: <llvm-back-end>, value :: <double-float>)
 => (result :: <llvm-value>);
  make(<llvm-float-constant>, type: $llvm-double-type, float: value)
end method;
