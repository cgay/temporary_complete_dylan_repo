module: compile-time-functions
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/ctfunc.dylan,v 1.7 1995/11/09 13:52:14 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.

define class <ct-function> 
    (<ct-value>, <annotatable>, <identity-preserving-mixin>)
  //
  // Some string useful for describing this function.  Used only for printing
  // and error messages.
  slot ct-function-name :: <string>,
    required-init-keyword: name:;
  //
  // The signature for this function.
  slot ct-function-signature :: <signature>,
    required-init-keyword: signature:;
  //
  // The definition this <ct-function> came from, or #f if it didn't come
  // from a definition.
  slot ct-function-definition :: false-or(<function-definition>),
    init-value: #f, init-keyword: definition:;
  //
  // List of the types for the closure vars for this function.  Only local
  // functions can have closure vars.
  slot ct-function-closure-var-types :: <list>,
    init-value: #(), init-keyword: closure-var-types:;
end;

define method print-object (ctv :: <ct-function>, stream :: <stream>) => ();
  pprint-fields(ctv, stream, name: ctv.ct-function-name);
end;

define method print-message (ctv :: <ct-function>, stream :: <stream>) => ();
  write(ctv.ct-function-name, stream);
end;

define method ct-value-cclass (ctv :: <ct-function>) => res :: <cclass>;
  specifier-type(#"<raw-function>");
end;


define constant $ct-function-dump-slots =
  list(info, #f, info-setter,
       ct-function-name, name:, #f,
       ct-function-signature, signature:, #f,
       ct-function-definition, definition:, #f,
       ct-function-closure-var-types, closure-var-types:, #f);

add-make-dumper(#"ct-function", *compiler-dispatcher*, <ct-function>,
		$ct-function-dump-slots,
		load-external: #t);


define class <ct-generic-function> (<ct-function>, <eql-ct-value>)
end;

define method ct-value-cclass (ctv :: <ct-generic-function>)
    => res :: <cclass>;
  specifier-type(#"<generic-function>");
end;

add-make-dumper(#"ct-generic-function", *compiler-dispatcher*,
		<ct-generic-function>, $ct-function-dump-slots,
		load-external: #t);



define class <ct-method> (<ct-function>)
  //
  // True if this method is hidden inside a generic function so we don't
  // need to generate a general entry for it.
  slot ct-method-hidden? :: <boolean>,
    init-value: #f, init-keyword: hidden:;
end;

define method ct-value-cclass (ctv :: <ct-method>) => res :: <cclass>;
  specifier-type(#"<method>");
end;

add-make-dumper(#"ct-method", *compiler-dispatcher*,
  <ct-method>,
  concatenate(
    $ct-function-dump-slots,
    list(ct-method-hidden?, hidden:, #f)),
  load-external: #t
);


define class <ct-entry-point> 
    (<ct-value>, <annotatable>, <identity-preserving-mixin>)
  //
  // The function this is an entry point for.
  slot ct-entry-point-for :: <ct-function>,
    required-init-keyword: for:;
  //
  // The kind of entry point.
  slot ct-entry-point-kind :: one-of(#"main", #"general", #"generic"),
    required-init-keyword: kind:;
end;

define method print-object (ctv :: <ct-entry-point>, stream :: <stream>) => ();
  pprint-fields(ctv, stream,
		for: ctv.ct-entry-point-for,
		kind: ctv.ct-entry-point-kind);
end;

define method print-message
    (ctv :: <ct-entry-point>, stream :: <stream>) => ();
  format(stream, "%s entry point for %s",
	 ctv.ct-entry-point-kind,
	 ctv.ct-entry-point-for.ct-function-name);
end;

define method ct-value-cclass (ctv :: <ct-entry-point>) => res :: <cclass>;
  specifier-type(#"<raw-pointer>");
end;

add-make-dumper(#"ct-entry-point", *compiler-dispatcher*,
  <ct-entry-point>,
  list(ct-entry-point-for, for:, #f,
       ct-entry-point-kind, kind:, #f),
  load-external: #t
);
