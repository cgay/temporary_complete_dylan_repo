module: front
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/front/fer-dump.dylan,v 1.14 1995/04/25 23:03:46 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.


// Id stuff.

define variable *id-table* = make(<table>);
define constant $id-vector = make(<stretchy-vector>);

define method reset-ids () => ();
  *id-table* := make(<table>);
  $id-vector.size := 0;
end;

define constant <id-able>
  = type-or(<region>, <expression>, <assignment>);

define method id (thing :: <id-able>) => res :: <integer>;
  let id = element(*id-table*, thing, default: #f);
  if (id)
    id;
  else
    let id = $id-vector.size;
    add!($id-vector, thing);
    element(*id-table*, thing) := id;
    id;
  end;
end;

define method id (id :: <integer>) => res :: <id-able>;
  unless (id < $id-vector.size)
    error("Nothing with id %d\n", id);
  end;
  $id-vector[id];
end;


define method print-object (thing :: <id-able>, stream :: <stream>) => ();
  write('{', stream);
  write-class-name(thing, stream);
  write(" [", stream);
  print(thing.id, stream);
  write("]}", stream);
end;




// Dump-fer itself.

define method dump-fer (thing, #key stream = *debug-output*) => ();
  pprint-logical-block(stream, body: curry(dump, thing));
  write('\n', stream);
end;

define generic dump (thing, stream) => ();

define method dump (thing :: <object>, stream :: <stream>) => ();
  write("{a ", stream);
  write-class-name(thing, stream);
  write('}', stream);
end;

define method dump (component :: <component>, stream :: <stream>) => ();
  for (meth in component.all-methods,
       first? = #t then #f)
    unless (first?)
      pprint-newline(#"mandatory", stream);
    end;
    dump(meth, stream);
  end;
end;

define method dump (region :: <simple-region>, stream :: <stream>) => ();
  for (assign = region.first-assign then assign.next-op,
       first? = #t then #f,
       while assign)
    unless (first?)
      pprint-newline(#"mandatory", stream);
    end;
    dump(assign, stream);
  end;
end;
      
define method dump (region :: <compound-region>, stream :: <stream>) => ();
  for (subregion in region.regions,
       first? = #t then #f)
    unless (first?)
      pprint-newline(#"mandatory", stream);
    end;
    dump(subregion, stream);
  end;
end;

define method dump (region :: <if-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "[%d]: IF (", region.id);
	     dump(region.depends-on.source-exp, stream);
	     write(')', stream);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.then-region, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write("ELSE", stream);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.else-region, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write("END", stream);
	   end);
end;

define method dump (region :: <block-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "[%d]: BLOCK", region.id);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.body, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write("END", stream);
	   end);
end;

define method dump (region :: <loop-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "[%d]: LOOP", region.id);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.body, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write("END", stream);
	   end);
end;

define method dump (region :: <exit>, stream :: <stream>) => ();
  format(stream, "[%d]: EXIT [%d]", region.id, region.block-of.id);
end;

define method dump (assignment :: <assignment>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "[%d]: ", assignment.id);
	     if (instance?(assignment, <let-assignment>))
	       format(stream, "let ");
	     end;
	     dump-defines(assignment.defines, stream);
	     write(' ', stream);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"fill", stream);
	     write(":= ", stream);
	     dump(assignment.depends-on.source-exp, stream);
	     write(';', stream);
	   end);
end;

define method dump (assignment :: <join-assignment>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "[%d]: ", assignment.id);
	     dump-defines(assignment.defines, stream);
	     write(' ', stream);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"fill", stream);
	     write("JOIN ", stream);
	     dump(assignment.depends-on.source-exp, stream);
	     write(';', stream);
	   end);
end;

define method dump-defines (defines :: false-or(<definition-site-variable>),
			    stream :: <stream>)
    => ();
  if (~defines)
    write("()", stream);
  elseif (~defines.definer-next)
    dump(defines, stream);
  else
    pprint-logical-block
      (stream,
       prefix: "(",
       body: method (stream)
	       for (def = defines then def.definer-next,
		    first? = #t then #f,
		    while def)
		 unless (first?)
		   write(", ", stream);
		   pprint-newline(#"fill", stream);
		 end;
		 dump(def, stream);
	       end;
	     end,
       suffix: ")");
  end;
end;

define method dump (op :: <operation>, stream :: <stream>) => ();
  format(stream, "%s[%d]", op.kind, op.id);
  dump-operands(op.depends-on, stream);
end;

define method kind (op :: <operation>) => res :: <string>;
  "???";
end;

define method kind (op :: <abstract-call>) => res :: <string>;
  "CALL";
end;

define method kind (op :: <local-call>) => res :: <string>;
  "LOCAL-CALL";
end;

define method kind (op :: <known-call>) => res :: <string>;
  "KNOWN-CALL";
end;

define method kind (op :: <unknown-call>) => res :: <string>;
  "UNKNOWN-CALL";
end;

define method kind (op :: <error-call>) => res :: <string>;
  "ERROR-CALL";
end;

define method kind (op :: <mv-call>) => res :: <string>;
  "MV-CALL";
end;

define method kind (op :: <prologue>) => res :: <string>;
  "PROLOGUE";
end;

define method kind (op :: <catcher>) => res :: <string>;
  "CATCHER";
end;

define method kind (op :: <pitcher>) => res :: <string>;
  "PITCHER";
end;

define method dump (op :: <primitive>, stream :: <stream>) => ();
  format(stream, "primitive %s[%d]", op.name, op.id);
  dump-operands(op.depends-on, stream);
end;

define method dump (op :: <pitcher>, stream :: <stream>) => ();
  format(stream, "PITCHER[%d]", op.id);
  dump-operands(op.depends-on, stream);
  format(stream, " to CATCHER[%d]", op.catcher.id);
end;

define method dump (op :: <set>, stream :: <stream>) => ();
  write("set ", stream);
  dump(op.variable.defn-name, stream);
  format(stream, "[%d]", op.id);
  dump-operands(op.depends-on, stream);
end;

define method dump-operands(dep :: false-or(<dependency>), stream :: <stream>)
    => ();
  pprint-logical-block
    (stream,
     prefix: "(",
     body: method (stream)
	     for (dep = dep then dep.dependent-next,
		  first? = #t then #f,
		  while dep)
	       unless (first?)
		 write(", ", stream);
		 pprint-newline(#"fill", stream);
	       end;
	       dump-expr(dep.source-exp, stream);
	     end;
	   end,
     suffix: ")");
end;

define method dump-expr (expr :: <expression>, stream :: <stream>) => ();
  dump(expr, stream);
end;

define method dump-expr (expr :: <lambda>, stream :: <stream>) => ();
  format(stream, "METHOD[%d] ", lambda.id);
end;

define method dump (var :: <abstract-variable>, stream :: <stream>) => ();
  dump(var.var-info, stream);
  format(stream, "[%d]", var.id);
end;

define method dump (var :: <initial-definition>, stream :: <stream>) => ();
  dump(var.var-info, stream);
  format(stream, "[%d]", var.definition-of.id);
end;

define method dump (info :: <debug-named-info>, stream :: <stream>) => ();
  write(as(<string>, info.debug-name), stream);
end;

define method dump (info :: <module-var-info>, stream :: <stream>) => ();
  dump(info.var-defn.defn-name, stream);
end;

define method dump (name :: <basic-name>, stream :: <stream>) => ();
  write(as(<string>, name.name-symbol), stream);
end;

define method dump (leaf :: <literal-constant>, stream :: <stream>) => ();
  dump(leaf.value, stream);
end;

define method dump (ct-value :: <ct-value>, stream :: <stream>) => ();
  print(ct-value, stream, level: 1, length: 3);
end;

define method dump (ct-value :: <cclass>, stream :: <stream>) => ();
  write(as(<string>, ct-value.cclass-name.name-symbol), stream);
end;

define method dump (leaf :: <definition-constant-leaf>, stream :: <stream>)
    => ();
  dump(leaf.const-defn.defn-name, stream);
  format(stream, "[%d]", leaf.id);
end;

define method dump (lambda :: <lambda>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "METHOD [%d] ", lambda.id);
	     pprint-logical-block
	       (stream,
		prefix: "(",
		body: method (stream)
			for (var = lambda.prologue.dependents.dependent.defines
			       then var.definer-next,
			     first? = #t then #f,
			     while: var)
			  unless (first?)
			    write(", ", stream);
			    pprint-newline(#"fill", stream);
			  end;
			  dump(var, stream);
			end;
		      end,
		suffix: ")");
	     write(' ', stream);
	     pprint-indent(#"block", 4, stream);
	     pprint-newline(#"fill", stream);
	     write("=> ", stream);
	     let res = lambda.depends-on;
	     if (res & res.dependent-next == #f)
	       dump(res.source-exp, stream);
	     else
	       pprint-logical-block
		 (stream,
		  prefix: "(",
		  body: method (stream)
			  for (dep = res then dep.dependent-next,
			       first? = #t then #f,
			       while: dep)
			    unless (first?)
			      write(", ", stream);
			      pprint-newline(#"fill", stream);
			    end;
			    dump(dep.source-exp, stream);
			  end;
			end,
		  suffix: ")");
	     end;
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(lambda.body, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write("END", stream);
	   end);
end;

define method dump
    (hairy-method :: <hairy-method-literal>, stream :: <stream>) => ();
  format(stream, "HAIRY-METHOD[%d]", hairy-method.id);
end;

define method dump
    (exit-function :: <exit-function>, stream :: <stream>) => ();
  format(stream, "EXIT-FUN[%d]", exit-function.id);
end;
