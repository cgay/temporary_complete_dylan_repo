module: cheese
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/optimize/primopt.dylan,v 1.4 1995/06/07 15:15:40 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.


define method optimize (component :: <component>, primitive :: <primitive>)
    => ();
  let info = primitive.info;

  let assign = primitive.dependents.dependent;
  local
    method assert-arg-types
	(dep :: false-or(<dependency>), arg-types :: <list>) => ();
      if (arg-types == #())
	if (dep)
	  error("Too many arguments to %%%%primitive %s", primitive.name);
	end;
      else
	let arg-type = arg-types.head;
	if (arg-type == #"rest")
	  let arg-type = arg-types.tail.head;
	  if (arg-type == #"cluster")
	    for (dep = dep then dep.dependent-next,
		 while: dep)
	      let arg = dep.source-exp;
	      unless (instance?(arg, <abstract-variable>)
			& instance?(arg.var-info, <values-cluster-info>))
		error("%%%%primitive %s expected a values cluster but got "
			"a regular variable.");
	      end;
	    end;
	  else
	    for (dep = dep then dep.dependent-next,
		 while: dep)
	      assert-type(component, assign, dep, arg-type);
	    end;
	  end;
	elseif (dep == #f)
	  error("Not enough arguments to %%%%primitive %s", primitive.name);
	else
	  if (arg-type == #"cluster")
	    let arg = dep.source-exp;
	    unless (instance?(arg, <abstract-variable>)
		      & instance?(arg.var-info, <values-cluster-info>))
	      error("%%%%primitive %s expected a values cluster but got "
		      "a regular variable.");
	    end;
	  else
	    assert-type(component, assign, dep, arg-type);
	  end;
	  assert-arg-types(dep.dependent-next, arg-types.tail);
	end;
      end;
    end;
  assert-arg-types(primitive.depends-on, info.primitive-arg-types);

  maybe-restrict-type(component, primitive, info.primitive-result-type);

  let transformer = info.primitive-transformer;
  if (transformer)
    transformer(component, primitive);
  end;
end;


// magic debugging primitives.

define-primitive-transformer
  (#"break",
   method (component :: <component>, primitive :: <primitive>) => ();
     break("Hit break primitive.");
     replace-expression(component, primitive.dependents,
			make-literal-constant(make-builder(component),
					      as(<ct-value>, #f)));
   end);


// Values manipulation primitives.

define-primitive-transformer
  (#"values",
   method (component :: <component>, primitive :: <primitive>) => ();
     let assign = primitive.dependents.dependent;
     let defns = assign.defines;
     if (defns & instance?(defns.var-info, <values-cluster-info>))
       // Assigning to a cluster.  Just compute a values type and propagate
       // it.
       for (dep = primitive.depends-on then dep.dependent-next,
	    types = #() then pair(dep.source-exp.derived-type, types),
	    while: dep)
       finally
	 maybe-restrict-type(component, primitive,
			     make-values-ctype(reverse!(types), #f));
       end;
     else
       // Assigning to a bunch of discreet variables.  Replace the assignment
       // with individual assignments for each value.
       let builder = make-builder(component);
       let next-var = #f;
       let let? = instance?(assign, <let-assignment>);
       for (var = defns then next-var,
	    val-dep = primitive.depends-on
	      then val-dep & val-dep.dependent-next,
	    while: var)
	 next-var := var.definer-next;
	 var.definer-next := #f;
	 let val = if (val-dep)
		     val-dep.source-exp;
		   else
		     make-literal-constant(builder, make(<literal-false>));
		   end;
	 if (let?)
	   build-let(builder, assign.policy, assign.source-location, var, val);
	 else
	   build-assignment(builder, assign.policy, assign.source-location,
			    var, val);
	 end;
       end;
       assign.defines := #f;
       // Insert the spred out assignments.
       insert-after(component, assign, builder.builder-result);
       // Nuke the original assignment.
       delete-and-unlink-assignment(component, assign);
     end;
   end);

define-primitive-transformer
  (#"canonicalize-results",
   method (component :: <component>, primitive :: <primitive>) => ();
     let nfixed-leaf = primitive.depends-on.dependent-next.source-exp;
     if (instance?(nfixed-leaf, <literal-constant>))
       let nfixed = nfixed-leaf.value.literal-value;
       let cluster = primitive.depends-on.source-exp;
       let type = cluster.derived-type;
       if (fixed-number-of-values?(type))
	 let orig-assign = primitive.dependents.dependent;
	 let builder = make-builder(component);
	 let temps = map(method (type)
			   make-local-var(builder, #"temp", type);
			 end,
			 type.positional-types);
	 build-assignment(builder, orig-assign.policy,
			  orig-assign.source-location, temps, cluster);
	 let op
	   = if (nfixed < type.min-values)
	       let fixed = copy-sequence(temps, end: nfixed);
	       let rest = copy-sequence(temps, start: nfixed);
	       let op = make-operation(builder, <primitive>, rest,
				       name: #"vector");
	       let rest-temp
		 = make-local-var(builder, #"temp", object-ctype());
	       build-assignment(builder, orig-assign.policy,
				orig-assign.source-location, rest-temp, op);
	       make-operation(builder, <primitive>,
			      concatenate(fixed, list(rest-temp)),
			      name: #"values");
	     else
	       let false = make-literal-constant(builder, as(<ct-value>, #f));
	       let falses = make(<list>, size: nfixed - type.min-values,
				 fill: false);
	       let empty-vect
		 = make-literal-constant(builder, as(<ct-value>, #[]));
	       make-operation(builder, <primitive>,
			      concatenate(temps, falses, list(empty-vect)),
			      name: #"values");
	     end;
	 replace-expression(component, orig-assign.depends-on, op);
	 insert-before(component, orig-assign, builder-result(builder));
       else
	 let types = make(<stretchy-vector>);
	 for (remaining = type.positional-types then remaining.tail,
	      index from 0 below min(type.min-values, nfixed),
	      until: remaining == #())
	   add!(types, remaining.head);
	 finally
	   unless (index == nfixed)
	     let rest = ctype-union(type.rest-value-type,
				    specifier-type(#"<false>"));
	     for (remaining = remaining then remaining.tail,
		  index from index below nfixed,
		  until: remaining == #())
	       add!(types, ctype-union(remaining.head, rest));
	     finally
	       for (index from index below nfixed)
		 add!(types, rest);
	       end;
	     end;
	   end;
	 end;
	 add!(types, specifier-type(#"<simple-object-vector>"));
	 maybe-restrict-type(component, primitive,
			     make-values-ctype(as(<list>, types), #f));
       end;
     end;
   end);

define-primitive-transformer
  (#"values-sequence",
   method (component :: <component>, primitive :: <primitive>) => ();
     for (vec = primitive.depends-on.source-exp
	    then vec.definer.depends-on.source-exp,
	  while: instance?(vec, <ssa-variable>))
     finally
       if (instance?(vec, <primitive>))
	 if (vec.name == #"vector")	 
	   for (value-dep = vec.depends-on then value-dep.dependent-next,
		values = #() then pair(value-dep.source-exp, values),
		while: value-dep)
	   finally
	     replace-expression
	       (component, primitive.dependents,
		make-operation(make-builder(component), <primitive>,
			       reverse!(values), name: #"values"));
	   end;
	 elseif (vec.name == #"canonicalize-results")
	   let vec-assign = vec.dependents.dependent;
	   let prim-assign = primitive.dependents.dependent;
	   if (vec-assign.region == prim-assign.region
		 & vec-assign.depends-on == vec.dependents)
	     let nfixed = vec.depends-on.dependent-next.source-exp;
	     if (instance?(nfixed, <literal-constant>) & nfixed.value = 0)
	       block (return)
		 for (assign = vec-assign.next-op then assign.next-op,
		      until: assign == prim-assign)
		   if ((instance?(assign.defines, <abstract-variable>)
			  & instance?(assign.defines.var-info,
				      <values-cluster-info>))
			 | consumes-cluster?(assign.depends-on))
		     return();
		   end;
		 end;
		 replace-expression(component, prim-assign.depends-on,
				    vec.depends-on.source-exp);
	       end;
	     end;
	   end;
	 end;
       end;
     end;
   end);

define method consumes-cluster? (expr :: <leaf>) => res :: <boolean>;
  #f;
end;

define method consumes-cluster? (expr :: <abstract-variable>)
    => res :: <boolean>;
  instance?(expr.var-info, <values-cluster-info>);
end;

define method consumes-cluster? (expr :: <operation>)
    => res :: <boolean>;
  block (return)
    for (dep = expr.depends-on then dep.dependent-next,
	 while: dep)
      if (consumes-cluster?(dep.source-exp))
	return(#t);
      end;
    end;
    #f;
  end;
end;

define-primitive-transformer
  (#"merge-clusters",
   method (component :: <component>, primitive :: <primitive>) => ();
     local
       method repeat (dep :: false-or(<dependency>),
		      prev :: false-or(<dependency>),
		      all-fixed? :: <boolean>)
	 if (dep)
	   let cluster = dep.source-exp;
	   let type = cluster.derived-type;
	   if (fixed-number-of-values?(type))
	     if (type.min-values == 0)
	       let next = dep.dependent-next;
	       if (prev)
		 prev.dependent-next := next;
	       else
		 primitive.depends-on := next;
	       end;
	       remove-dependency-from-source(component, dep);
	       repeat(next, prev, all-fixed?);
	     else
	       repeat(dep.dependent-next, dep, all-fixed?);
	     end;
	   else
	     repeat(dep.dependent-next, dep, #f);
	   end;
	 elseif (all-fixed?)
	   let next = #f;
	   for (dep = primitive.depends-on then next,
		while: dep)
	     next := dep.dependent-next;
	     let cluster = dep.source-exp;
	     expand-cluster(component, cluster,
			    cluster.derived-type.min-values);
	   finally
	     for (dep = primitive.depends-on then dep.dependent-next,
		  vars = #() then pair(dep.source-exp, vars),
		  while: dep)
	     finally
	       replace-expression
		 (component, primitive.dependents,
		  make-operation(make-builder(component), <primitive>,
				 reverse!(vars), name: #"values"));
	     end;
	   end;
	 elseif (primitive.depends-on.dependent-next == #f)
	   replace-expression(component, primitive.dependents,
			      primitive.depends-on.source-exp);
	 end;
       end method repeat;
     repeat(primitive.depends-on, #f, #t);
   end method);


// Foreign code support primitives

define-primitive-transformer
  (#"call-out",
   method (component :: <component>, primitive :: <primitive>) => ();
     let func-dep = primitive.depends-on;
     begin
       let func = func-dep.source-exp;
       unless (instance?(func, <literal-constant>)
		 & instance?(func.value, <literal-string>))
	 compiler-error("The function in call-out isn't a constant string.");
       end;
     end;
     let result-dep = func-dep.dependent-next;
     begin
       let result-type = result-dep.source-exp.dylan-type-for-c-type;
       maybe-restrict-type(component, primitive, result-type);
     end;
     let assign = primitive.dependents.dependent;
     local
       method repeat (dep :: false-or(<dependency>))
	 if (dep)
	   let type = dep.source-exp.dylan-type-for-c-type;
	   let next = dep.dependent-next;
	   if (next)
	     assert-type(component, assign, next, type);
	     repeat(next.dependent-next);
	   else
	     compiler-error("Type spec with no argument in call-out");
	   end;
	 end;
       end;
     repeat(result-dep.dependent-next);
   end);

define method dylan-type-for-c-type (leaf :: <leaf>) => res :: <values-ctype>;
  if (instance?(leaf, <literal-constant>))
    let ct-value = leaf.value;
    if (instance?(ct-value, <literal-symbol>))
      let c-type = ct-value.literal-value;
      select (c-type)
	#"char", #"short", #"int", #"long",
	#"unsigned-char", #"unsigned-short", #"unsigned-int" =>
	  specifier-type(#"<fixed-integer>");
	#"ptr" => specifier-type(#"<raw-pointer>");
	#"float" => specifier-type(#"<single-float>");
	#"double" => specifier-type(#"<double-float>");
	#"long-double" => specifier-type(#"<extended-float>");
	#"void" => make-values-ctype(#(), #f);
      end;
    else
      object-ctype();
    end;
  else
    object-ctype();
  end;
end;



// Boolean canonicalization stuff.

define-primitive-transformer
  (#"as-boolean",
   method (component :: <component>, primitive :: <primitive>) => ();
     let arg = primitive.depends-on.source-exp;
     let arg-type = arg.derived-type;
     let false-type = specifier-type(#"<false>");
     if (csubtype?(arg.derived-type, specifier-type(#"<boolean>")))
       replace-expression(component, primitive.dependents, arg);
     elseif (~ctypes-intersect?(arg-type, false-type))
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, #t)));
     end;
   end);
			  
define-primitive-transformer
  (#"not",
   method (component :: <component>, primitive :: <primitive>) => ();
     let arg = primitive.depends-on.source-exp;
     let arg-type = arg.derived-type;
     let false-type = specifier-type(#"<false>");
     if (csubtype?(arg-type, false-type))
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, #t)));
     elseif (~ctypes-intersect?(arg-type, false-type))
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, #f)));
     elseif (instance?(arg, <ssa-variable>))
       let arg-source = arg.definer.depends-on.source-exp;
       if (instance?(arg-source, <primitive>) & arg-source.name == #"not")
	 let source-source = arg-source.depends-on.source-exp;
	 let op = make-operation(make-builder(component), <primitive>,
				 list(source-source), name: #"as-boolean");
	 replace-expression(component, primitive.dependents, op);
       end;
     end;
   end);

define-primitive-transformer
  (#"==",
   method (component :: <component>, primitive :: <primitive>) => ();
     let x = primitive.depends-on.source-exp;
     let x-type = x.derived-type;
     let y = primitive.depends-on.dependent-next.source-exp;
     let y-type = y.derived-type;
     if (~ctypes-intersect?(x-type, y-type))
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, #f)));
     elseif (instance?(x-type, <singleton-ctype>) & x-type == y-type)
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, #t)));
     end;
   end);

define-primitive-transformer
  (#"initialized?",
   method (component :: <component>, primitive :: <primitive>) => ();
     let x = ct-initialized?(primitive.depends-on.source-exp);
     unless (x == #"can't tell")
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, x)));
     end;
   end);

define method ct-initialized?
    (expr :: <expression>) => res :: one-of(#t, #f, #"can't tell");
  #t;
end;

define method ct-initialized?
    (expr :: <uninitialized-value>) => res :: one-of(#t, #f, #"can't tell");
  #f;
end;

define method ct-initialized?
    (expr :: <abstract-variable>) => res :: one-of(#t, #f, #"can't tell");
  #"can't tell";
end;

define method ct-initialized?
    (expr :: <ssa-variable>) => res :: one-of(#t, #f, #"can't tell");
  ct-initialized?(expr.definer.depends-on.source-exp);
end;


// Fixnums.

define-primitive-transformer
  (#"fixnum-=",
   method (component :: <component>, primitive :: <primitive>) => ();
     let x = primitive.depends-on.source-exp;
     let x-type = x.derived-type;
     let y = primitive.depends-on.dependent-next.source-exp;
     let y-type = y.derived-type;
     if (~ctypes-intersect?(x-type, y-type))
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, #f)));
     elseif (instance?(x-type, <limited-integer-ctype>)
	       & x-type == y-type
	       & x-type.low-bound = x-type.high-bound)
       replace-expression(component, primitive.dependents,
			  make-literal-constant(make-builder(component),
						as(<ct-value>, #t)));
     end;
   end);

define-primitive-transformer
  (#"fixnum-<",
   method (component :: <component>, primitive :: <primitive>) => ();
     let x = primitive.depends-on.source-exp;
     let x-type = x.derived-type;
     let y = primitive.depends-on.dependent-next.source-exp;
     let y-type = y.derived-type;
     if (instance?(x-type, <limited-integer-ctype>)
	   & instance?(y-type, <limited-integer-ctype>))
       if (x-type.high-bound < y-type.low-bound)
	 replace-expression(component, primitive.dependents,
			    make-literal-constant(make-builder(component),
						  as(<ct-value>, #t)));
       elseif (x-type.low-bound >= y-type.high-bound)
	 replace-expression(component, primitive.dependents,
			    make-literal-constant(make-builder(component),
						  as(<ct-value>, #f)));
       end;
     end;
   end);

