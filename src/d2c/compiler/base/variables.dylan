module: variables
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/variables.dylan,v 1.11 1995/10/13 15:11:17 ram Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

// $Dylan-User-Uses -- internal.
//
// Sequence of modules (in the Dylan library) that are automatically used
// by the implicit Dylan-User module that gets created in each library.
//
define constant $Dylan-User-Uses :: <vector> = #[#"Dylan"];


// *Module-System-Initialized* -- internal.
//
// Set to #t once all the magic pre-defines have been made.  Once this
// happens, module's use chains must be fully established before more
// variables can be defined in that module.  Until then, defined
// variables are assumed to be homed in the module they are defined
// in (i.e. not created elsewhere and imported).
// 
define variable *Module-System-Initialized* :: <boolean> = #f;


// <library> -- exported.
//
define class <library> (<object>)
  //
  // The name of this library, as a symbol.
  slot library-name :: <symbol>, required-init-keyword: name:;
  //
  // #t once the defn for this library has been processed, #f otherwise.
  slot defined? :: <boolean>, init-value: #f;
  //
  // Vector of <use> structures for all the libraries this library
  // uses.  Uninitialized until the defn for this library has been
  // processed.
  slot used-libraries :: <simple-object-vector>;
  //
  // Hash table mapping names to modules for modules exported directly
  // from this library.  Modules re-exported after being imported from
  // somewhere else are not listed in here.  Not filled in until the
  // library is actually defined.
  slot exported-modules :: <object-table>,
    init-function: curry(make, <object-table>);
  //
  // Hash table mapping names to modules for modules homed in this
  // library.
  slot local-modules :: <object-table>,
    init-function: curry(make, <object-table>);
end;

define method print-object (lib :: <library>, stream :: <stream>) => ();
  pprint-fields(lib, stream, name: lib.library-name);
end;

// library-name -- exported.
//
define generic library-name (lib :: <library>) => name :: <symbol>;

// <module> -- exported.
//
define class <module> (<object>)
  //
  // The name of this module, as a symbol.
  slot module-name :: <symbol>, required-init-keyword: name:;
  //
  // The library this module lives in.
  slot module-home :: <library>, required-init-keyword: home:;
  //
  // #t once the defn for this module has been processed, #f otherwise.
  slot defined? :: <boolean>, init-value: #f;
  //
  // Vector of <use> structures for all the modules this module
  // uses.  Uninitialized until the defn for this module has been
  // processed.
  slot used-modules :: <simple-object-vector>;
  //
  // Hash table mapping names to syntactic categories.
  slot module-syntax-table :: <table>,
    init-function: curry(make, <table>);
  //
  // Hash table mapping names to variables for variables accessable
  // in this module.
  slot variables :: <object-table>,
    init-function: curry(make, <object-table>);
  //
  // Hash table mapping names to variables for all variables exported
  // from this module.
  slot exported-variables :: <object-table>,
    init-function: curry(make, <object-table>);
  //
  // #t if variables and exported-variables have been populated with
  // everything imported from the various uses, #f until then.
  slot completed? :: <boolean>, init-value: #f;
  //
  // #t while we are processing the various uses, #f otherwise.  Used
  // to detect circular use chains.
  slot busy? :: <boolean>, init-value: #f;
end;

define method print-object (mod :: <module>, stream :: <stream>) => ();
  pprint-fields(mod, stream, name: mod.module-name);
end;

define method print-message (mod :: <module>, stream :: <stream>) => ();
  format(stream, "module %s, library %s",
	 mod.module-name,
	 mod.module-home.library-name);
end;

define method initialize (mod :: <module>, #next next-method, #key) => ();
  next-method();
  //
  // Fill in the built in core words.
  //
  let table = mod.module-syntax-table;
  table[#"define"] := <define-token>;
  table[#"end"] := <end-token>;
  table[#"generic"] := <generic-token>;
  table[#"handler"] := <handler-token>;
  table[#"let"] := <let-token>;
  table[#"local"] := <local-token>;
  table[#"macro"] := <macro-token>;
  table[#"otherwise"] := <otherwise-token>;
  table[#"seal"] := <seal-token>;
end;

// module-name -- exported.
//
define generic module-name (mod :: <module>) => name :: <symbol>;

// <variable> -- exported.
// 
define class <variable> (<object>)
  //
  // The name of the variable, as a symbol.
  slot variable-name :: <symbol>, required-init-keyword: name:;
  // 
  // The module this variable lives in.  Note: this is not necessarily
  // the same as where it is defined, because the create clause in
  // define module forms creates a variable, but requires it to be
  // defined elsewhere.
  slot variable-home :: <module>, required-init-keyword: home:;
  //
  // All the modules where this variable is accessable.
  slot accessing-modules :: <stretchy-vector>,
    init-function: curry(make, <stretchy-vector>, size: 0);
  //
  // #t if originally in an export or create clause, #f otherwise.
  slot exported? :: <boolean>, init-value: #f, init-keyword: exported:;
  slot created? :: <boolean>, init-value: #f, init-keyword: created:;
  //
  // The definition for this variable, or #f if not yet defined.
  slot variable-definition :: union(<definition>, <false>),
    init-value: #f;
  //
  // List of FER transformers for this variable.  Gets propagated to the defn
  // when the defn is installed.
  slot variable-transformers :: <list>, init-value: #();
end;

define method print-object (var :: <variable>, stream :: <stream>) => ();
  pprint-fields(var, stream, name: var.variable-name);
end;

// variable-name -- exported.
//
define generic variable-name (var :: <variable>) => name :: <symbol>;

// variable-definition -- exported.
//
define generic variable-definition (var :: <variable>)
    => defn :: union(<false>, <definition>);

// <use> -- exported.
//
define class <use> (<object>)
  //
  // The name of the library/module being used.
  slot name-used :: <symbol>,
    required-init-keyword: name:;
  //
  // Either a vector of names to import, of #t for all.
  slot imports :: union(<simple-object-vector>, <true>),
    required-init-keyword: imports:;
  //
  // Either a string prefix or #f if none.
  slot prefix :: union(<string>, <false>),
    required-init-keyword: prefix:;
  //
  // Vector of names to exclude.  Only non-empty if import is #t.
  slot excludes :: <simple-object-vector>,
    required-init-keyword: excludes:;
  //
  // Vector of renamings.  Any name in here is also in imports.
  slot renamings :: <simple-object-vector>,
    required-init-keyword: renamings:;
  //
  // Either a vector of names to re-export, or #t for all.
  slot exports :: union(<simple-object-vector>, <true>),
    required-init-keyword: exports:;
end;

define method print-object (u :: <use>, stream :: <stream>) => ();
  pprint-fields(u, stream,
		name-used: u.name-used,
		imports: u.imports,
		prefix: u.prefix,
		excludes: u.excludes,
		renamings: u.renamings,
		exports: u.exports);
end;

// <renaming> -- exported.
//
define class <renaming> (<object>)
  //
  // The name in the module/library being imported.
  slot orig-name :: <symbol>, required-init-keyword: orig-name:;
  //
  // The name the module/library is being imported as.
  slot new-name :: <symbol>, required-init-keyword: new-name:;
end;

define method print-object (ren :: <renaming>, stream :: <stream>) => ();
  pprint-fields(ren, stream, orig-name: ren.orig-name, new-name: ren.new-name);
end;


// Library access stuff.

// $Libraries -- internal.
//
// Hash table mapping names to <library> structures.
//
define constant $Libraries :: <object-table> = make(<object-table>);

// find-library -- exported.
//
// Find the library with the given name.  If create: is #t and the
// library doesn't already exist, create it.  Otherwise, return #f.
//
define method find-library (name :: <symbol>, #key create: create?)
    => result :: union(<library>, <false>);
  //
  // Look it up in the global table.
  // 
  let lib = element($Libraries, name, default: #f);

  if (lib)
    //
    // Already exists, just return it.
    //
    lib;

  elseif (create?)
    //
    // Make a new library and stuff it into the global table.
    //
    let new = make(<library>, name: name);
    element($Libraries, name) := new;
    //
    // Create the built in dylan-user module.  Even though the
    // dylan-user module is defined in this library, we record the
    // home of the dylan-user module as the dylan library, so that the
    // dylan-user module's uses (dylan and extensions) get looked up
    // in the correct library.
    // 
    let dylan-user = make(<module>,
			  name: name,
			  home: find-library(#"Dylan", create: #t));
    new.local-modules[name] := dylan-user;
    //
    // And now define the dylan-user module.
    // 
    note-module-definition(new, #"Dylan-User",
			   map(method (name)
				 make(<use>, name: name, imports: #t,
				      prefix: #f, excludes: #[],
				      renamings: #[], exports: #[]);
			       end,
			       $Dylan-User-Uses),
		  #[], #[]);
    //
    // And return the new library.
    // 
    new;

  else
    //
    // It doesn't exist.
    //
    #f;
  end;
end method;


// note-library-definition -- exported.
//
// Establish the definition for the named library.  Uses is a sequence
// of <use> structures, and exports is a sequence of names from export
// clauses.
//
define method note-library-definition (name :: <symbol>, uses :: <sequence>,
				       exports :: <sequence>)
    => ();
  let lib = find-library(name, create: #t);
  if (lib.defined?)
    error("Library %s is already defined.", name);
  end;
  lib.defined? := #t;
  lib.used-libraries := as(<simple-object-vector>, uses);
  //
  // Fill in exported-modules, creating modules as needed.
  //
  for (name in exports)
    lib.exported-modules[name] := find-module(lib, name, create: #t);
  end;
  //
  // ### Check to see that there are no ambiguities.
  //
end method;


// Module access stuff.

// find-module -- exported.
//
// Return the named module in the given library, or #f if there is no
// such module.  If create? is true, then create it instead of
// returning #f.
//
define method find-module (lib :: <library>, name :: <symbol>,
			   #key create: create?)
    => result :: union(<module>, <false>);
  let mod = element(lib.local-modules, name, default: #f);
  if (mod)
    mod;
  elseif (create?)
    let new = make(<module>, name: name, home: lib);
    lib.local-modules[name] := new;
    if (lib.defined?)
      // ### Check to see if this name classes with any of the
      // imported names.
      #f;
    end;
    new;
  elseif (lib.defined?)
    find-in-library-uses(lib, name, #f);
  else
    error("Library %s has not been defined yet", lib.library-name);
  end;
end method;

// find-exported-module -- internal.
//
// Find the module in the library, but only if it is exported.
//
define method find-exported-module (lib :: <library>, name :: <symbol>)
    => result :: union(<module>, <false>);
  unless (lib.defined?)
    error("Undefined library %s", lib.library-name);
  end;
  element(lib.exported-modules, name, default: #f)
    | find-in-library-uses(lib, name, #t);
end;

// find-in-library-uses -- internal.
//
// Search through the use clauses for this library trying to find one
// that imports the named module.  If exported-only is true, then
// ignore any modules that are not re-exported.
//
define method find-in-library-uses (lib :: <library>, name :: <symbol>,
				    exported-only :: <boolean>)
    => result :: union(<module>, <false>);
  block (return)
    for (u in lib.used-libraries)
      let orig-name = guess-orig-name(u, name, exported-only);
      if (orig-name)
	let used-lib = find-library(u.name-used);
	unless (used-lib)
	  error("Undefined library %s", u.name-used);
	end;
	let imported = find-exported-module(used-lib, orig-name);
	if (imported)
	  return(imported);
	end;
      end;
    end for;
    #f;
  end block;
end method;

// guess-orig-name -- internal.
//
// If name could be imported via the given use, return the original
// name of the exported variable.  In other words, apply any renaming
// or prefixing in reverse.  If name isn't imported via this use, then
// return #f.
//
define method guess-orig-name (u :: <use>, name :: <symbol>,
			       exported-only :: <boolean>)
    => result :: union(<symbol>, <false>);
  if (~exported-only | u.exports == #t | member?(name, u.exports))
    block (return)
      //
      // First check the renamings.
      // 
      for (ren in u.renamings)
	if (ren.new-name == name)
	  return(ren.orig-name);
	end;
      end;
      //
      // Next, remove the prefix, if there is one.
      //
      let guess = remove-prefix(u.prefix, name);
      unless (guess)
	return(#f);
      end;
      //
      // Now check it against the imports and excludes.
      //
      if (u.imports == #t)
	~member?(guess, u.excludes) & guess;
      else
	member?(guess, u.imports) & guess;
      end;
    end;
  end;
end method;

// remove-prefix -- internal.
//
// Either return name with the prefix removed, or #f if name isn't
// prefixed with prefix.  We also have a method for a prefix of #f
// just so that we don't have to test for that case before calling
// remove-prefix.
// 
define method remove-prefix (prefix :: <string>, name :: <symbol>)
    => result :: <symbol>;
  let name-str = as(<string>, name);
  if (name-str.size > prefix.size)
    block (return)
      for (name-char in name-str, prefix-char in prefix)
	unless (as-uppercase(name-char) == as-uppercase(prefix-char))
	  return(#f);
	end;
      finally
	as(<symbol>, copy-sequence(name-str, start: prefix.size));
      end;
    end;
  end;
end;
//
define method remove-prefix (prefix :: <false>, name :: <symbol>)
    => result :: <symbol>;
  name;
end;

// note-module-definition -- exported.
//
// Establish the definition for the named module in the given library.
// Uses is a sequence of <use> objects, and exports and creates are
// the names from the exports and creates options.
//
// We don't actually do anything with the uses just yet in order to
// simplify bootstrapping.
//
define method note-module-definition (lib :: <library>, name :: <symbol>,
				      uses :: <sequence>,
				      exports :: <sequence>,
				      creates :: <sequence>)
    => ();
  let mod = find-module(lib, name, create: #t);
  if (mod.defined?)
    error("Module %s is already defined.", name);
  end;
  //
  // Mark it as defined, and record the uses for later.
  // 
  mod.defined? := #t;
  mod.used-modules := as(<simple-object-vector>, uses);
  //
  // Make variables for all the names in the export clauses.
  // 
  for (name in exports)
    let old = element(mod.variables, name, default: #f);
    if (old)
      mod.exported-variables[name] := old;
      old.exported? := #t;
    else
      let new = make(<variable>, name: name, home: mod, exported: #t);
      mod.variables[name] := new;
      mod.exported-variables[name] := new;
      add!(new.accessing-modules, mod);
    end;
  end;
  //
  // Make variables for all the names in the create clauses.
  // 
  for (name in creates)
    let old = element(mod.variables, name, default: #f);
    if (old)
      if (old.exported?)
	error("%s in both a create clause and an export clause in module %s",
	      name, mod.module-name);
      elseif (old.defined?)
	error("%s in create clause for module %s, so must be "
		"defined elsewhere.",
	      name, mod.module-name);
      else
	mod.exported-variables[name] := old;
	old.created? := #t;
      end;
    else
      let new = make(<variable>, name: name, home: mod, created: #t);
      mod.variables[name] := new;
      mod.exported-variables[name] := new;
      add!(new.accessing-modules, mod);
    end;
  end;
end;

// complete-module -- internal
//
// Called whenever we need the complete variable names for the given
// module and we don't have them yet.  This is where the use clauses
// are actually processed.
// 
define method complete-module (mod :: <module>) => ();
  //
  // First, make sure we arn't already trying to complete this module
  // and that it has been defined.
  //
  if (mod.busy?)
    error("Circular module use chain detected at module %s", mod.module-name);
  end;
  unless (mod.defined?)
    error("Module %s has not been defined yet.", mod.module-name);
  end;
  mod.busy? := #t;
  //
  // Pull in everything from the uses.
  //
  for (u in mod.used-modules)
    let used-mod = find-module(mod.module-home, u.module-name);
    unless (used-mod)
      error("No module %s in library %s",
	    u.module-name, mod.module-home.library-name);
    end;

    local
      method do-import (var :: <variable>, orig-name :: <symbol>,
			new-name :: <symbol>)
	//
	// Check to see if the new import causes a clash.
	// 
	let old = element(mod.variables, new-name, default: #f);
	if (old & ~(old == var))
	  if (new-name == orig-name)
	    error("Importing %s from module %s into module %s clashes.",
		  new-name, mod.module-name, used-mod.module-name);
	  else
	    error("Importing %s from module %s into module %s as %s clashes.",
		  orig-name, mod.module-name, used-mod.module-name, new-name);
	  end;
	end;
	//
	// Verify that any changes to the syntax table that need to be
	// made because of this import are okay.
	//
	check-syntax-table-additions(mod.module-syntax-table,
				     var.variable-definition,
				     new-name);
	//
	// No clash, so stick the variable in our table of local
	// variables, and our table of exported variables if this
	// import is being re-exported.
	//
	mod.variables[new-name] := var;
	if (u.exports == #t | member?(new-name, u.exports))
	  mod.exported-variables[new-name] := var;
	end;
	//
	// Next, actually modify the syntax table.
	//
	make-syntax-table-additions(mod.module-syntax-table,
				    var.variable-definition,
				    new-name);
	//
	// And finally, stick us in the set of modules who can access this
	// variable.
	//
	unless (member?(mod, var.accessing-modules))
	  add!(var.accessing-modules, mod);
	end;
      end method;

    if (u.imports == #t)
      //
      // Import everything exported.
      //
      unless (used-mod.completed?)
	//
	// In order to import all we have to know everything that the
	// used module is exporting.
	//
	complete-module(used-mod);
      end;
      //
      // Import all the exported variables, unless compute-new-name
      // tells us it should be skipped.
      //
      for (var in used-mod.exported-variables)
	let orig-name = var.variable-name;
	let new-name = compute-new-name(u, orig-name);
	if (new-name)
	  do-import(var, orig-name, new-name);
	end;
      end;
    else
      //
      // Import everything listed.
      //
      for (orig-name in u.imports)
	let var = find-exported-variable(used-mod, orig-name);
	let new-name = compute-new-name(u, orig-name);
	do-import(var, orig-name, new-name);
      end;
    end;
  end for;
  //
  // Now completed and no longer busy.
  //
  mod.completed? := #t;
  mod.busy? := #f;
end method;
	
// compute-new-name -- internal
//
// Figure out how name gets renamed or prefixed when imported via use.
// Return #f if it should be excluded.
//
define method compute-new-name (u :: <use>, name :: <symbol>)
    => result :: union(<symbol>, <false>);
  block (return)
    //
    // First, check the renamings.
    //
    for (ren in u.renamings)
      if (ren.orig-name == name)
	return(ren.new-name);
      end;
    end;
    //
    // Punt if the name should be excluded.
    //
    if (member?(name, u.excludes))
      return(#f);
    end;
    //
    // Next, add the prefix if there is one.
    //
    if (u.prefix)
      as(<symbol>, concatenate(u.prefix, as(<string>, name)));
    else
      name;
    end;
  end;
end method;


// Variable stuff.

// find-varible -- exported.
//
// Return the named variable from the given module.  If it doesn't
// already exist, either create it (if create is true) or return #f
// (if create is false).
//
// We look before bothering to complete the module so that we can
// magically pre-define some things and be able to find them before we
// get around to actually defining the module they are in.
//
define method find-variable (name :: <basic-name>, #key create: create?)
    => result :: union(<variable>, <false>);
  let mod = name.name-module;
  let sym = name.name-symbol;
  let var = element(mod.variables, sym, default: #f);
  if (var)
    var;
  elseif (~mod.completed? & *Module-System-Initialized*)
    complete-module(mod);
    find-variable(name, create: create?);
  elseif (create?)
    let new = make(<variable>, name: sym, home: mod);
    mod.variables[sym] := new;
    add!(new.accessing-modules, mod);
    new;
  else
    #f;
  end;
end method;

// find-exported-variable -- internal.
//
// Return the named variable if it is there and exported, or #f if
// not.  Again, we don't actually complete the module unless we have
// to.
// 
define method find-exported-variable (mod :: <module>, name :: <symbol>)
    => result :: union(<variable>, <false>);
  unless (mod.defined?)
    error("Module %s is not defined.", mod.module-name);
  end;
  let var = element(mod.exported-variables, name, default: #f);
  if (var)
    var;
  elseif (mod.completed?)
    #f;
  else
    complete-module(mod);
    element(mod.exported-variables, name, default: #f);
  end;
end method;

// note-variable-definition -- exported.
//
// Note that name is defined in module.
// 
define method note-variable-definition (defn :: <definition>)
    => ();
  //
  // Get the variable, creating it if necessary.
  //
  let name = defn.defn-name;
  let mod = name.name-module;
  let var = find-variable(defn.defn-name, create: #t);
  //
  // Make sure this module either is or is not the varibles home,
  // depending on whether the variable was in a create define module
  // clause or not.
  //
  if (var.created?)
    if (var.variable-home == mod)
      error("%s in create clause for module %s, so must be "
	      "defined elsewhere.",
	    name.name-symbol, mod.module-name);
    end;
  else
    unless (var.variable-home == mod)
      error("%s is imported into module %s, so can't be defined locally.",
	    name.name-symbol, mod.module-name);
    end;
  end;
  //
  // Make sure the variable isn't already defined.
  //
  if (var.variable-definition)
    unless (instance?(var.variable-definition, <implicit-definition>))
      error("%s in module %s multiply defined.",
	    name.name-symbol, mod.module-name);
    end;
  end;
  //
  // Make sure this defn doesn't introduce any problems in the
  // syntax tables of modules that can access this variable.
  //
  for (accessing-module in var.accessing-modules)
    for (imported-var keyed-by imported-name in accessing-module.variables)
      if (imported-var == var)
	check-syntax-table-additions(accessing-module.module-syntax-table,
				     defn, imported-name);
      end;
    end;
  end;
  //
  // Okay, record the definition and adjust the syntax tables.
  //
  var.variable-definition := defn;
  for (accessing-module in var.accessing-modules)
    for (imported-var keyed-by imported-name in accessing-module.variables)
      if (imported-var == var)
	make-syntax-table-additions(accessing-module.module-syntax-table,
				    defn, imported-name);
      end;
    end;
  end;
  //
  // And if it is a function definition and we have some function info,
  // propagate it over.
  if (~empty?(var.variable-transformers)
	& instance?(defn, <function-definition>))
    defn.function-defn-transformers := var.variable-transformers;
  end;
end;
//
// We ignore implicit definitions for variables already defined or from outside
// the module (unless the variable was set up with a create clause).
// 
define method note-variable-definition (defn :: <implicit-definition>,
					#next next-method)
  let var = find-variable(defn.defn-name, create: #t);
  unless (var.variable-definition)
    if (var.variable-home == defn.defn-name.name-module | var.created?)
      next-method();
    end;
  end;
end;


// Initilization stuff.

// $Dylan-Library and $Dylan-Module -- exported.
//
// The Dylan library and module.
//
define constant $Dylan-Library
  = find-library(#"Dylan", create: #t);
define constant $Dylan-Module
  = find-module($Dylan-Library, #"Dylan", create: #t);

// *Current-Library* and *Current-Module* -- exported.
// 
// The Current Library and Module during a parse, or #f if we arn't parsing
// at the moment.
// 
define variable *Current-Library* :: false-or(<library>) = #f;
define variable *Current-Module* :: false-or(<module>) = #f;

// done-initializing-module-system -- exported.
//
// Indicate that we are done initializing the module system.
//
define method done-initializing-module-system () => ();
  *Module-System-Initialized* := #t;
end;


// Shorthands

// dylan-name -- ???
// 
define method dylan-name (sym :: <symbol>) => res :: <basic-name>;
  make(<basic-name>, symbol: sym, module: $Dylan-module);
end;

// dylan-var -- exported.
//
// Return the variable for name in the dylan module.
// 
define method dylan-var (name :: <symbol>, #key create: create?)
    => res :: union(<variable>, <false>);
  find-variable(dylan-name(name), create: create?);
end;

// dylan-defn -- exported.
//
// Return the definition for name in the dylan module.
// 
define method dylan-defn (name :: <symbol>)
    => res :: union(<definition>, <false>);
  let var = dylan-var(name);
  var & var.variable-definition;
end;

// dylan-value -- exported.
//
// Returns the compile-time value for the given name in the dylan module,
// or #f if it isn't defined.
// 
define method dylan-value (name :: <symbol>)
    => res :: union(<false>, <ct-value>);
  let defn = dylan-defn(name);
  defn & defn.ct-value;
end;

