documented: #t
module: c-declarations
copyright: Copyright (C) 1994, Carnegie Mellon University
	   All rights reserved.
	   This code was produced by the Gwydion Project at Carnegie Mellon
	   University.  If you are interested in using this code, contact
	   "Scott.Fahlman@cs.cmu.edu" (Internet).
rcs-header: $Header: 

//======================================================================
//
// Copyright (c) 1994  Carnegie Mellon University
// All rights reserved.
//
//======================================================================

//======================================================================
// "C-decl-write.dylan" contains code to write out Dylan code corresponding to
// various c declarations.  This will likeley be replaced in later versions by
// code which simply builds a parse tree or produces native code.  The current
// version has the advantage of being highly portable -- the Dylan code it
// writes depends upon a relatively small set of primitives defined in module
// "extern". 
//======================================================================

//------------------------------------------------------------------------
// Exported function declarations.
//------------------------------------------------------------------------

// Writes out a list of symbols which must be defined, in a format compatible
// with make-init.pl.  This should provide a portable mechanism for handling
// static linking of libraries.
//
define generic write-mindy-includes
    (file :: union(<string>, <false>), decls :: <sequence>) => ();

// Writes out appropriate code to load object file and insure that all desired
// objects are included.  Returns a string which can be included in a
// "find-c-function" call so that the symbols will be found.
//
define generic write-file-load
    (object-file :: union(<string>, <false>), decls :: <sequence>,
     stream :: <stream>)
 => (load-string :: <string>);

// Writes out all the Dylan code corresponding to one <declaration>.  The
// exact behavior can, of course, vary widely depending on the variety of
// declaration.  "Load-string" is a magic cookie which is passed to any calss
// to "find-c-pointer" or "find-c-function" -- it specifies the
// <foreign-file> (if any) which should contain the desired definition. 
//
// Most of the code in this file goes to support this single operations.
//
define generic write-declaration
    (decl :: <struct-declaration>, load-string :: <string>, stream :: <stream>)
 => ();

//------------------------------------------------------------------------
// Support code
//------------------------------------------------------------------------

// C accessor returns a string with the appropriate Dylan code for
// "dereferencing" the named parameter, assuming that the result of the
// operation will have the characteristics of "type".  "Equated" specifies the
// name of the actual type for non-static (i.e. pointer) values which have
// been "equate:"ed, or #f otherwise.
//
// The offset (which may be an integer or a string which contains an
// integral Dylan expression) ends up being added to the address.  This is
// useful for accessing a slot of a larger structure.
//
define generic c-accessor
    (type :: <type-declaration>, offset :: union(<integer>, <string>),
     parameter :: <string>, equated :: <string>)
 => (result :: <string>);

// import-value returns a string which contains dylan code for making a Dylan
// value out of the raw value in variable "var".  This will either be a call
// to the appropriate mapping function for the type named in "decl" or (if no
// mapping is defined) can just be the raw variable
//
define method import-value (decl :: <declaration>, var :: <string>)
 => (result :: <string>);
  if (decl.mapped-name ~= decl.type-name)
    format-to-string("import-value(%s, %s)", decl.mapped-name, var);
  else
    var;
  end if;
end method import-value;

// See import-value above.  This method does the equivalent for converting
// Dylan values into raw "C" values.
//
define method export-value (decl :: <declaration>, var :: <string>)
 => (result :: <string>);
  if (decl.mapped-name ~= decl.type-name)
    format-to-string("export-value(%s, %s)", decl.type-name, var);
  else
    var;
  end if;
end method export-value;

// Private variable used (and modified) by anonymous-name.
define variable anonymous-count :: <integer> = 0;

// Generates a new name for a function or type.  We don't actually check that
// the user hasn't generated an identical name, but rely instead upon the
// relative obscurity of a variable named "anonymous-???".
//
define method anonymous-name () => (name :: <string>);
  let name = format-to-string("anonymous-%d", anonymous-count);
  anonymous-count := anonymous-count + 1;
  name;
end method anonymous-name;

// This method simply converts integral parameters into strings for later
// processing by other methods.
//
define method c-accessor
    (type :: <type-declaration>, offset :: <integer>, parameter :: <string>,
     equated :: <string>)
 => (result :: <string>);
  c-accessor(type, format-to-string("%d", offset), parameter, equated);
end method c-accessor;

define method c-accessor
    (type :: <integer-type-declaration>, offset :: <string>,
     parameter :: <string>, equated :: <string>)
 => (result :: <string>);
  // Each builtin integer type specifies its own accessor function.  We can
  // safely ignore "equated".
  format-to-string("%s(%s, offset: %s)",
		   type.accessor-name, parameter, offset);
end method c-accessor;

define method c-accessor
    (type :: <float-type-declaration>, offset :: <string>,
     parameter :: <string>, equated :: <string>)
 => (result :: <string>);
  "error(\"C structure accessors for floating point fields "
    "not yet supported.\")";
end method c-accessor;

define method c-accessor
    (type :: <enum-declaration>, offset :: <string>,
     parameter :: <string>, equated :: <string>)
 => (result :: <string>);
  format-to-string("unsigned-long-at(%s, offset: %s)",
		   parameter, offset);
end method c-accessor;

define method c-accessor
    (type :: union(<pointer-declaration>, <function-type-declaration>),
     offset :: <string>, parameter :: <string>,
     equated :: <string>)
 => (result :: <string>);
  format-to-string("pointer-at(%s, offset: %s, class: %s)",
		   parameter, offset, equated);
end method c-accessor;

define method c-accessor
    (type :: type-or(<struct-declaration>, <union-declaration>,
		     <vector-declaration>),
     offset :: <string>, parameter :: <string>, equated :: <string>)
 => (result :: <string>);
  // This one is non-intuitive.  When you "dereference" a pointer or a slot
  // whose contents are a "structure" or "vector" (as distinct from a
  // pointer), you just get a pointer to it, since the actual "contents" can't
  // be expressed.  You can, of course, get a portion of the "contents" by
  // accessing a slot or element.
  //
  // Note that the only way you should get a "vector" is as a structure slot.
  // If we had a declaration like "(*)(foo [])" (i.e. a "pointer" to a
  // "vector") then this routine could produce bad results.  However, this
  // sort of declaration is either impossible or very uncommon.
  format-to-string("as(%s, %s + %s)", equated, parameter, offset);
end method c-accessor;

define method c-accessor
    (alias :: <typedef-declaration>, offset :: <string>, parameter :: <string>,
     equated :: <string>)
 => (result :: <string>);
  // Push past an alias to get the real accessor.
  c-accessor(alias.type, offset, parameter, equated);
end method c-accessor;

// This method writes out accessors for a single slot.  All non-excluded slots
// get "getter" methods, but there may not be a setter method if the slot is
// declared "read-only" or if the value is something unsettable like a
// struct or vector.  (Note that you can set *pointers* to structs or pointers
// to "vectors" -- the check only applies to inline structs, unions, and
// vectors.) 
//
define method write-c-accessor-method
    (compound-type :: <type-declaration>, slot-name :: <string>,
     slot-type :: <slot-declaration>, offset :: <integer>, stream :: <stream>)
 => ();
  let real-type = true-type(slot-type.type);
  // Write getter method
  format(stream,
	 "define %s method %s\n"
	 "    (ptr :: %s) => (result :: %s);\n"
	 "  %s;\n"
	 "end method %s;\n\n",
	 slot-type.sealed-string, slot-name, compound-type.mapped-name,
	 slot-type.mapped-name,
	 import-value(slot-type, c-accessor(slot-type.type, offset,
					    export-value(compound-type, "ptr"),
					    slot-type.type-name)),
	 slot-name);

  if (~slot-type.read-only
	& ~instance?(real-type, type-or(<struct-declaration>,
					<union-declaration>,
					<vector-declaration>)))
    // Write setter method
    format(stream,
	   "define %s method %s-setter\n"
	   "    (value :: %s, ptr :: %s) => (result :: %s);\n"
	   "  %s := %s;\n"
	   "  value;\n"
	   "end method %s-setter;\n\n",
	   slot-type.sealed-string, slot-name, slot-type.mapped-name,
	   compound-type.mapped-name, slot-type.mapped-name,
	   c-accessor(slot-type.type, offset,
		      export-value(compound-type, "ptr"), slot-type.type-name),
	   export-value(slot-type, "value"), slot-name);
  end if;
end method write-c-accessor-method;

//------------------------------------------------------------------------
// Methods definitions for exported functions
//------------------------------------------------------------------------

// For structures, we must define the basic class, write accessors for each of
// the slots, write an "identity" accessor function, and specify the size of
// the structure.  "Write-c-accessor-method" will do all the real work of
// creating slot accessors.
//
define method write-declaration
    (decl :: <struct-declaration>, load-string :: <string>, stream :: <stream>)
 => ();
  if (~decl.equated?)
    format(stream, "define class %s (<statically-typed-pointer>) end;\n\n",
	   decl.dylan-name);
    local method slot-accessors
	      (end-offset :: <integer>, c-slot :: <declaration>)
	   => (end-offset :: <integer>);
	    let name = c-slot.dylan-name;
	    let slot-type = c-slot.type;
	    let (end-offset, start-offset)
	      = aligned-slot-position(end-offset, slot-type);
	    if (~c-slot.excluded?)
	      write-c-accessor-method(decl, name, c-slot,
				      start-offset, stream);
	    end if;
	    end-offset;
	  end method slot-accessors;

    // This may still be an "incomplete type".  If so, we define the class,
    // but don't write any slot accessors.
    if (decl.members) reduce(slot-accessors, 0, decl.members) end if;

    format(stream,
	   "define method pointer-value (value :: %s, #key index = 0) "
	     "=> (result :: %s);\n"
	     "  value + index * %d;\nend method pointer-value;\n\n",
	   decl.dylan-name, decl.dylan-name, decl.c-type-size);

    // Finally write out a "content-size" function for use by "make", etc.
    format(stream,
	   "define method content-size "
	     "(value :: limited(<class>, subclass-of: %s)) "
	     "=> (result :: <integer>);\n"
	     "  %d;\nend method content-size;\n\n",
	   decl.dylan-name, decl.c-type-size);
  end if;
end method write-declaration;

// Unions are just like structs (see above) except that the size and offsets
// are calculated differently.
//
define method write-declaration
    (decl :: <union-declaration>, load-string :: <string>, stream :: <stream>)
 => ();
  if (~decl.equated?)
    format(stream, "define class %s (<statically-typed-pointer>) end;\n\n",
	   decl.dylan-name);

    // This may still be an "incomplete type".  If so, we define the class, but
    // don't write any slot accessors.
    if (decl.members)
      for (c-slot in decl.members)
	if (~c-slot.excluded?)
	  let name = c-slot.dylan-name;
	  write-c-accessor-method(decl, name, c-slot, 0, stream);
	end if;
      end for;
    end if;

    format(stream,
	   "define method pointer-value (value :: %s, #key index = 0) "
	     "=> (result :: %s);\n"
	     "  value + index * %d;\nend method pointer-value;\n\n",
	   decl.dylan-name, decl.dylan-name, decl.c-type-size);

    // Finally write out a "content-size" function for use by "make", etc.
    format(stream,
	   "define method content-size "
	     "(value :: limited(<class>, subclass-of: %s)) "
	     " => (result :: <integer>);\n  %d;\n"
	     "end method content-size;\n\n",
	   decl.dylan-name, decl.c-type-size);
  end if;
end method write-declaration;

// Enums are defined to be a limited subtype of <integer>, and constants
// values are written for each literal.
//
define method write-declaration
    (decl :: <enum-declaration>, load-string :: <string>, stream :: <stream>)
 => ();
  if (~decl.equated?)
    let type-name = decl.dylan-name;
    
    // This may still be an "incomplete type".  If so, we just define the class
    // as a synonym for <integer>
    if (decl.members)
      // Portability note: as soon as we have maximum and minimum integers,
      // install them here.
      let min-enum = reduce(method (a, b) min(a, b.constant-value) end method,
			    32767, decl.members);
      let max-enum = reduce(method (a, b) max(a, b.constant-value) end method,
			    -32768, decl.members);
      format(stream,
	     "define constant %s = limited(<integer>, min: %d, max: %d);\n",
	     type-name, min-enum, max-enum);

      for (literal in decl.members)
	let name = literal.dylan-name;
	let int-value = literal.constant-value;
	format(stream, "define constant %s :: %s = %d;\n",
	       name, type-name, int-value);
      finally
	write("\n", stream);
      end for;
    else
      format(stream, "define constant %s = <integer>;\n\n",
	     type-name);
    end if;
  end if;
end method write-declaration;

// We write getter functions for global variables and write setter functions
// if appropriate (see comments for "write-c-accessor-method" above).
//
define method write-declaration
    (decl :: <variable-declaration>, load-string :: <string>,
     stream :: <stream>)
 => ();
  let name = decl.dylan-name;
  let raw-name = anonymous-name();
  let real-type = true-type(decl.type);

  // First get the address of the c object...
  format(stream, "define constant %s = find-c-pointer(\"%s\"%s);\n",
	 raw-name, decl.simple-name, load-string);

  // Write a getter method (with an empty parameter list)
  format(stream, "define %s method %s () => (%s);\n  %s;\nend method %s;\n\n",
	 decl.sealed-string, decl.getter, decl.mapped-name,
	 import-value(decl,
		      c-accessor(decl.type, 0, raw-name, decl.type-name)),
	 decl.getter);

  // Write a setter method
  if (~decl.read-only 
	& ~instance?(real-type, type-or(<struct-declaration>,
					<union-declaration>,
					<vector-declaration>)))
    format(stream,
	   "define %s method %s (value :: %s) => (result :: %s);\n"
	     "  %s := %s;\n  value;\nend method %s;\n\n",
	   decl.sealed-string, decl.setter, decl.type.mapped-name,
	   decl.mapped-name,
	   c-accessor(decl.type, 0, raw-name, decl.type-name),
	   export-value(decl, "value"), decl.setter);
  end if;
end method write-declaration;

// Separates the parameters between those used as input values and those used
// as result values.  In-out parameters will show up in both sequences.
//
define method split-parameters (decl :: <function-type-declaration>)
 => (in-params :: <sequence>, out-params :: <sequence>);
  let params = as(<list>, decl.parameters);
  let in-params
    = choose(method (p)
	       (p.direction == #"default" | p.direction == #"in"
		  | p.direction == #"in-out");
	     end method, params);
  let out-params
    = choose(method (p) p.direction == #"in-out" | p.direction == #"out" end,
	     params);
  if (decl.result.type ~= void-type)
    values(in-params, pair(decl.result, out-params));
  else
    values(in-params, out-params);
  end if;
end method split-parameters;

// Functions are tricky.  We must find the raw C routine, handle type
// selection for parameters, do special handling for "out" parameters, and
// call any appropriate type mapping routines.  Most of this is pretty
// straightforward, but rather long and tedious.
//
define method write-declaration
    (decl :: <function-declaration>, load-string :: <string>,
     stream :: <stream>)
 => ();
  let raw-name = anonymous-name();
  let (in-params, out-params) = split-parameters(decl.type);
  let params = decl.type.parameters;

  // First get the raw c function ...
  if (decl.type.result.type == void-type)
    format(stream, "define constant %s = find-c-function(\"%s\"%s);\n",
	   raw-name, decl.simple-name, load-string)
  else
    format(stream,
	   "define constant %s\n  = constrain-c-function("
	     "find-c-function(\"%s\"%s), #(), #t, list(%s));\n",
	   raw-name, decl.simple-name, load-string,
	   decl.type.result.type-name);
  end if;

  // ... then create a more robust method as a wrapper.
  format(stream, "define method %s\n    (", decl.dylan-name);
  for (arg in in-params, count from 1)
    if (count > 1) write(", ", stream) end if;
    case
      instance?(arg, <varargs-declaration>) =>
	format(stream, "#rest %s", arg.dylan-name);
      otherwise =>
	format(stream, "%s :: %s", arg.dylan-name, arg.mapped-name);
    end case;
  end for;
  write(")\n => (", stream);
  for (arg in out-params, count from 1)
    if (count > 1) write(", ", stream) end if;
    format(stream, "%s :: %s", arg.dylan-name, arg.mapped-name);
  end for;
  write(");\n", stream);

  for (arg in out-params)
    // Don't create a new variable if the existing variable is already the
    // right sort of pointer.
    if (instance?(arg, <arg-declaration>)
	  & (arg.direction == #"out"
	       | arg.type.dylan-name ~= arg.original-type.dylan-name))
      format(stream, "  let %s-ptr = make(%s);\n",
	     arg.dylan-name, arg.original-type.type-name);
      if (arg.direction == #"in-out")
	format(stream, "  %s-ptr.pointer-value := %s;\n",
	       arg.dylan-name, export-value(arg, arg.dylan-name));
      end if;
    end if;
  end for;

  if (decl.type.result.type ~= void-type)
    write("  let result-value\n    = ", stream);
  else
    write("  ", stream);
  end if;

  if (~params.empty? & instance?(last(params), <varargs-declaration>))
    format(stream, "apply(%s, ", raw-name);
  else
    format(stream, "%s(", raw-name);
  end if;
  for (count from 1, arg in params)
    if (count > 1) write(", ", stream) end if;
    if (instance?(arg, <varargs-declaration>))
      write(arg.dylan-name, stream);
    elseif (arg.direction == #"in-out" | arg.direction == #"out")
      format(stream, "%s-ptr", arg.dylan-name);
    else
      write(export-value(arg, arg.dylan-name), stream);
    end if;
  end for;
  write(");\n", stream);

  for (arg in out-params)
    if (instance?(arg, <arg-declaration>))
      format(stream, "  let %s-value = %s;\n",
	     arg.dylan-name,
	     import-value(arg, format-to-string("pointer-value(%s-ptr)",
						arg.dylan-name)));
      if (arg.type.dylan-name ~= arg.original-type.dylan-name)
	format(stream, "destroy(%s-ptr);\n", arg.dylan-name);
      end if;
    end if;
  end for;

  write("  values(", stream);
  for (arg in out-params, count from 1)
    if (count > 1) write(", ", stream) end if;
    if (instance?(arg, <arg-declaration>))
      format(stream, "%s-value", arg.dylan-name);
    else
      write(import-value(arg, "result-value"), stream);
    end if;
  end for;

  format(stream, ");\nend method %s;\n\n", decl.dylan-name);
end method write-declaration;

// We don't really handle function types, since we can't really define them in
// dylan.  We simply define them to be <statically-typed-pointer>s and assume
// that anybody who tries to pass one as a parameter gets it right.  This will
// be fleshed out more when we have an implementation which can handle
// callbacks properly.
//
define method write-declaration
    (decl :: <function-type-declaration>, load-string :: <string>,
     stream :: <stream>)
 => ();
  if (~decl.equated?)
    // Equate this type to "<statically-typed-pointer>" as a placeholder.
    // We may want to change this later.
    format(stream, "define constant %s = <statically-typed-pointer>;\n\n",
	   decl.dylan-name)
  end if;
end method write-declaration;

// Vectors likely still need some work.  Fake it for now.
//
define method write-declaration
    (decl :: <vector-declaration>, load-string :: <string>,
     stream :: <stream>)
 => ();
  if (~decl.equated?)
    // Just use the "equivalent" pointer type.  We probably will want to change
    // this later.
    format(stream, "define constant %s = %s;\n\n",
	   decl.dylan-name, decl.pointer-equiv.dylan-name);
  end if;
end method write-declaration;

// Typedefs are just aliases.  Define a constant which is initialized to the
// original type.  Because "typedef struct foo foo" is such a common case and
// would lead to conflicts, we check for it specially and ignore the typedef
// if it occurs. 
//
define method write-declaration
    (decl :: <typedef-declaration>, load-string :: <string>,
     stream :: <stream>)
 => ();
  // We must special case this one since there are so many declarations of the
  // form "typedef struct foo foo".
  if (~decl.equated? & decl.dylan-name ~= decl.type.dylan-name)
    format(stream, "define constant %s = %s;\n\n",
	   decl.dylan-name, decl.type.dylan-name);
  end if;
end method write-declaration;

// Only "simple" macros will appear amongst the declarations, and even those
// are not guaranteed to be compile time values.  None-the-less, we run them
// through the parser and see if it can come up with either a single specific
// declaration (in which case we treat it as an alias) or with a compile time
// value, which we will declare as a constant.  In other words,
//   #define foo 3
// will yield
//   define constant $foo 3
// and 
//   #define bar "char *"
// might yield
//   define constant <bar> = <c-string>
// (but only if the user had equated "char *" to <c-string>).  Some other
// routine has the task of figuring out what sort of a declaration we are
// aliasing and compute the appropriate sort of name.
//
define method write-declaration
    (decl :: <macro-declaration>, load-string :: <string>,
     stream :: <stream>)
 => ();
  let raw-value = decl.constant-value;
  let value = select (raw-value by instance?)
		<declaration> => raw-value.dylan-name;
		<integer>, <float> => format-to-string("%=", raw-value);
		<string> => format-to-string("\"%s\"", raw-value);
		<token> => raw-value.string-value;
	      end select;
  format(stream, "define constant %s = %s;\n\n", decl.dylan-name, value);
end method write-declaration;

// For pointers, we need "dereference" and "content-size" functions.  This is
// pretty strightforward.
//
define method write-declaration
    (decl :: <pointer-declaration>, load-string :: <string>,
     stream :: <stream>)
 => ();
  if (decl.equated? | decl.dylan-name = decl.referent.dylan-name)
    values();
  else 
    let target-type = decl.referent;
    let target-name = target-type.dylan-name;
    let target-map = target-type.mapped-name;

    // First get the raw c function ...
    format(stream, "define class %s (<statically-typed-pointer>) end class;\n",
	   decl.dylan-name);
    format(stream,
	   "define method pointer-value\n"
	     "    (ptr :: %s, #key index = 0)\n => (result :: %s);\n  ",
	   decl.dylan-name, target-map);
    write(import-value(target-type,
		       c-accessor(target-type,
				  format-to-string("index * %d",
						   target-type.c-type-size),
				  "ptr", target-type.type-name)),
	  stream);
    write(";\nend method pointer-value;\n\n", stream);
    
    // Write setter method
    format(stream,
	   "define method pointer-value-setter\n"
	     "    (value :: %s, ptr :: %s, #key index = 0)\n"
	     " => (result :: %s);\n  ",
	   target-map, decl.dylan-name, target-map);
    write(c-accessor(target-type,
		     format-to-string("index * %d", target-type.c-type-size),
		     "ptr", target-type.type-name),
	  stream);
    format(stream, " := %s;\n  value;\nend method pointer-value-setter;\n\n",
	   export-value(target-type, "value"));

    // Finally write out a "content-size" function for use by "make", etc.
    format(stream,
	   "define method content-size "
	     "(value :: limited(<class>, subclass-of: %s)) "
	     "=> (result :: <integer>);\n  %d;\n"
	     "end method content-size;\n\n",
	   decl.dylan-name, target-type.c-type-size)
  end if;
end method write-declaration;

// Writes out appropriate code to load object file and insure that all desired
// objects are included.  Returns a string which can be included in a
// "find-c-function" call so that the symbols will be found.
//
define method write-file-load
    (object-files :: <sequence>, decls :: <sequence>,
     stream :: <stream>)
 => (load-string :: <string>);
  if (~empty?(object-files))
    let names = map(simple-name,
		    choose(rcurry(instance?, <value-declaration>), decls));
    let file-name = anonymous-name();
    format(stream, "define constant %s\n  = load-object-file(#(", file-name);
    for (comma = #f then #t, file in object-files)
      if (comma) write(", ", stream) end if;
      format(stream, "\"%s\"", file);
    end for;
    write("), include: #(", stream);
    for (comma = #f then #t, name in names)
      if (comma) write(", ", stream) end if;
      format(stream, "\"%s\"", name);
    end for;
    write("));\n\n", stream);
    concatenate(", file: ", file-name);
  else
    ""
  end if;
end method write-file-load;

// Writes out a list of symbols which must be defined, in a format compatible
// with make-init.pl.  This should provide a portable mechanism for handling
// static linking of libraries.
//
define method write-mindy-includes
    (file :: union(<string>, <false>), decls :: <sequence>) => ();
  if (file)
    let stream = make(<file-stream>, name: file, direction: #"output");
    for (decl in decls)
      select (decl by instance?)
	<function-declaration> => format(stream, "%s()\n", decl.simple-name);
	<object-declaration> => format(stream, "%s\n", decl.simple-name);
	otherwise => #f;
      end select;
    end for;
    close(stream);
  end if;
end method write-mindy-includes;
