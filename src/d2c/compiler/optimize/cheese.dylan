module: front
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/optimize/cheese.dylan,v 1.32 1995/04/28 00:38:37 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.


define variable *do-sanity-checks* = #f;
define method enable-sanity-checks () => (); *do-sanity-checks* := #t; end;
define method disable-sanity-checks () => (); *do-sanity-checks* := #f; end;

define variable *print-shit* = #f;
define method print-shit () => (); *print-shit* := #t; end;
define method dont-print-shit () => (); *print-shit* := #f; end;


define method optimize-component (component :: <component>) => ();
  let done = #f;
  until (done)
    if (*do-sanity-checks*)
      check-sanity(component);
    end;
    if (*print-shit*) dump-fer(component) end;
    if (component.initial-definitions)
      let init-defn = component.initial-definitions;
      component.initial-definitions := init-defn.next-initial-definition;
      init-defn.next-initial-definition := #f;
      if (*print-shit*)
	format(*debug-output*,
	       "\n********* considering %= for ssa conversion\n\n",
	       init-defn.definition-of);
      end;
      maybe-convert-to-ssa(component, init-defn);
    elseif (component.reoptimize-queue)
      let dependent = component.reoptimize-queue;
      component.reoptimize-queue := dependent.queue-next;
      dependent.queue-next := #"absent";
      if (*print-shit*)
	format(*debug-output*, "\n********** about to optimize %=\n\n",
	       dependent);
      end;
      optimize(component, dependent);
    else
      local method try (function, what)
	      if (*print-shit* & what)
		format(*debug-output*, "\n********** %s\n\n", what);
	      end;
	      function(component);
	      component.initial-definitions | component.reoptimize-queue;
	    end;
      (*do-sanity-checks* & try(assure-all-done, #f))
	| try(identify-tail-calls, "finding tail calls")
	| try(add-type-checks, "adding type checks")
	| try(environment-analysis, "running environment analysis")
	| (done := #t);
    end;
  end;
end;



// SSA conversion.

define method maybe-convert-to-ssa
    (component :: <component>, defn :: <initial-definition>) => ();
  let var :: <initial-variable> = defn.definition-of;
  if (var.definitions.size == 1)
    let assign = defn.definer;
    let ssa = make(<ssa-variable>,
		   dependents: var.dependents,
		   derived-type: var.var-info.asserted-type,
		   var-info: var.var-info,
		   definer: assign,
		   definer-next: defn.definer-next);
    for (other = assign.defines then other.definer-next,
	 prev = #f then other,
	 until: other == defn)
    finally
      if (prev)
	prev.definer-next := ssa;
      else
	assign.defines := ssa;
      end;
    end;
    delete-definition(component, defn);
    for (dep = var.dependents then dep.source-next,
	 while: dep)
      unless (dep.source-exp == var)
	error("The dependent's source-exp wasn't the var we were trying "
		"to replace?");
      end;
      dep.source-exp := ssa;
      queue-dependent(component, dep.dependent);
    end;
    queue-dependent(component, assign);
  end;
end;


// Optimizations.

define generic optimize
    (component :: <component>, dependent :: <dependent-mixin>)
    => ();

define method optimize
    (component :: <component>, dependent :: <dependent-mixin>)
    => ();
  // By default, do nothing.
end;



// Assignment optimization.

define method side-effect-free? (expr :: <expression>) => res :: <boolean>;
  #f;
end;

define method side-effect-free?
    (var :: <abstract-variable>) => res :: <boolean>;
  #t;
end;

define method side-effect-free?
    (var :: <global-variable>) => res :: <boolean>;
  if (var.var-info.var-defn.ct-value)
    #t;
  else
    #f;
  end;
end;

define method side-effect-free? (const :: <constant>) => res :: <boolean>;
  #t;
end;

define method side-effect-free?
    (func :: <function-literal>) => res :: <boolean>;
  #t;
end;


define method pure-expression? (expr :: <expression>) => res :: <boolean>;
  #f;
end;

define method pure-expression? (var :: <ssa-variable>) => res :: <boolean>;
  #t;
end;

define method pure-expression? (var :: <constant>) => res :: <boolean>;
  #t;
end;

define method pure-expression? (var :: <function-literal>) => res :: <boolean>;
  #t;
end;


define method defines-unneeded? (defn :: <false>) => res :: <boolean>;
  #t;
end;

define method defines-unneeded? (defn :: <ssa-variable>)
    => res :: <boolean>;
  if (defn.dependents | defn.needs-type-check?)
    #f;
  else
    defines-unneeded?(defn.definer-next);
  end;
end;

define method defines-unneeded? (defn :: <initial-definition>)
    => res :: <boolean>;
  if (defn.definition-of.dependents | defn.needs-type-check?)
    #f;
  else
    defines-unneeded?(defn.definer-next);
  end;
end;


define method optimize
    (component :: <component>, assignment :: <assignment>) => ();
  let dependency = assignment.depends-on;
  let source = dependency.source-exp;
  let source-type = source.derived-type;
  let defines = assignment.defines;
  
  if (source-type == empty-ctype())
    insert-exit-after(component, assignment, component);
    for (defn = assignment.defines then defn.definer-next,
	 while: defn)
      delete-definition(component, defn);
    end;
    assignment.defines := #f;
  else
    if (defines-unneeded?(defines) & side-effect-free?(source))
      delete-and-unlink-assignment(component, assignment);
    else
      if (pure-expression?(source))
	if (instance?(defines.var-info, <values-cluster-info>))
	  if (instance?(source, <ssa-variable>)
		& instance?(source.var-info, <values-cluster-info>))
	    maybe-propagate-copy(component, defines, source);
	  end;
	else
	  unless (instance?(source, <ssa-variable>)
		    & instance?(source.var-info, <values-cluster-info>))
	    maybe-propagate-copy(component, defines, source);
	    let next = defines.definer-next;
	    if (next)
	      let false =
		make-literal-constant(make-builder(component),
				      make(<literal-false>));
	      for (var = next then var.definer-next,
		   while: var)
		maybe-propagate-copy(component, var, false);
	      end;
	    end;
	  end;
	end;
      end;

      if (instance?(defines & defines.var-info, <values-cluster-info>))
	maybe-restrict-type(component, defines, source-type);
      else
	for (var = defines then var.definer-next,
	     index from 0 below source-type.min-values,
	     positionals = source-type.positional-types then positionals.tail,
	     while: var)
	  maybe-restrict-type(component, var, positionals.head);
	finally
	  if (var)
	    let false-type = dylan-value(#"<false>");
	    for (var = var then var.definer-next,
		 positionals = positionals then positionals.tail,
		 while: var)
	      let type = if (positionals == #())
			   source-type.rest-value-type;
			 else
			   positionals.head;
			 end;
	      maybe-restrict-type(component, var,
				  ctype-union(type, false-type));
	    end;
	  end;
	end;
      end;
    end;
  end;
end;

define method maybe-propagate-copy (component :: <component>,
				    var :: <ssa-variable>,
				    value :: <expression>)
    => ();
  unless (var.needs-type-check?)
    // Change all references to this variable to be references to value
    // instead.
    let next = #f;
    let prev = #f;
    for (dep = var.dependents then next,
	 while: dep)
      next := dep.source-next;

      let dependent = dep.dependent;
      if (okay-to-propagate?(dependent, value))
	// Remove the dependency from the source.
	if (prev)
	  prev.source-next := next;
	else
	  var.dependents := next;
	end;

	// Link it into the new value.
	dep.source-exp := value;
	dep.source-next := value.dependents;
	value.dependents := dep;

	// Queue the dependent for reoptimization.
	queue-dependent(component, dependent);
      else
	prev := dep;
      end;
    end;
    
    // If we removed all the uses of var, queue var's defn for reoptimization.
    unless (var.dependents)
      queue-dependent(component, var.definer);
    end;
  end;
end;

define method okay-to-propagate? (dependent :: <dependent-mixin>,
				  value :: <expression>)
    => res :: <boolean>;
  #f;
end;

define method okay-to-propagate? (dependent :: <assignment>,
				  value :: <expression>)
    => res :: <boolean>;
  #t;
end;

define method okay-to-propagate? (dependent :: union(<operation>, <if-region>),
				  value :: <leaf>)
    => res :: <boolean>;
  #t;
end;

define method okay-to-propagate? (dependent :: <lambda>,
				  value :: <abstract-variable>)
    => res :: <boolean>;
  #t;
end;



define method maybe-propagate-copy (component :: <component>,
				    var :: <abstract-variable>,
				    value :: <expression>)
    => ();
end;


// Call optimization.

define method optimize (component :: <component>, call :: <unknown-call>)
    => ();
  let func-dep = call.depends-on;
  unless (func-dep)
    error("No function in a call?");
  end;
  // Dispatch of the thing we are calling.
  optimize-unknown-call(component, call, func-dep.source-exp);
end;

define method optimize-unknown-call
    (component :: <component>, call :: <unknown-call>, func :: <leaf>)
    => ();
  // Assert that the function is a function.
  assert-type(component, call.dependents.dependent, call.depends-on,
	      function-ctype());
end;

define method optimize-unknown-call
    (component :: <component>, call :: <unknown-call>, func :: <lambda>)
    => ();
  // Convert it into either a known or an error call.
  let assign = call.dependents.dependent;
  for (arg-dep = call.depends-on.dependent-next then arg-dep.dependent-next,
       var = func.prologue.dependents.dependent.defines
	 then var.definer-next,
       while: arg-dep & var)
    assert-type(component, assign, arg-dep, var.var-info.asserted-type);
  finally
    if (arg-dep | var)
      compiler-warning("Wrong number of arguments.");
      change-call-kind(component, call, <error-call>);
    else
      change-call-kind(component, call, <local-call>);
    end;
  end;
end;

define method optimize-unknown-call
    (component :: <component>, call :: <unknown-call>,
     func :: <definition-constant-leaf>)
    => ();
  optimize-unknown-call(component, call, func.const-defn);
end;

define method optimize-unknown-call
    (component :: <component>, call :: <unknown-call>,
     defn :: <abstract-constant-definition>)
    => ();
  // Assert that the function is a function.
  assert-type(component, call.dependents.dependent, call.depends-on,
	      function-ctype());
end;

define method optimize-unknown-call
    (component :: <component>, call :: <unknown-call>,
     defn :: <function-definition>)
    => ();
  let sig = defn.function-defn-signature;
  maybe-restrict-type(component, call, sig.returns);
end;

define method optimize-unknown-call
    (component :: <component>, call :: <unknown-call>,
     defn :: <abstract-method-definition>)
    => ();
  let func-dep = call.depends-on;
  let sig = defn.function-defn-signature;
  maybe-restrict-type(component, call, sig.returns);
  if (sig.next? == #f & sig.rest-type == #f & sig.key-infos == #f)
    let assign = call.dependents.dependent;
    for (arg-dep = func-dep.dependent-next then arg-dep.dependent-next,
	 count from 0,
	 specializer in sig.specializers,
	 while: arg-dep)
      assert-type(component, assign, arg-dep, specializer);
    finally
      if (arg-dep)
	compiler-warning("Too many arguments.");
	change-call-kind(component, call, <error-call>);
      elseif (count == sig.specializers.size)
	let leaf = defn.method-defn-leaf;
	if (leaf)
	  remove-dependency-from-source(component, func-dep);
	  func-dep.source-exp := leaf;
	  func-dep.source-next := leaf.dependents;
	  leaf.dependents := func-dep;
	  // We just set the derived type instead of using maybe-restrict-type
	  // because we don't need the propagation aspects of maybe-res-type
	  // because change-call-kind will queue the call no matter way.
	  // So we can avoid the extra overhead of maybe-restrict-type.
	  call.derived-type := leaf.result-type;
	  change-call-kind(component, call, <known-call>);
	end;
      else
	compiler-warning("Too few arguments.");
	change-call-kind(component, call, <error-call>);
      end;
    end;
  end;
end;

define method optimize-unknown-call
    (component :: <component>, call :: <unknown-call>, func :: <exit-function>)
    => ();
  maybe-expand-exit-function(component, call, func);
end;

define method change-call-kind
    (component :: <component>, call :: <abstract-call>, new-kind :: <class>)
    => ();
  let new = make(new-kind, dependents: call.dependents,
		 depends-on: call.depends-on,
		 derived-type: call.derived-type);
  for (dep = call.depends-on then dep.dependent-next,
       while: dep)
    dep.dependent := new;
  end;
  for (dep = call.dependents then dep.source-next,
       while: dep)
    dep.source-exp := new;
  end;
  queue-dependent(component, new);
end;

define method optimize
    (component :: <component>, call :: union(<known-call>, <local-call>))
    => ();
  maybe-restrict-type(component, call, call.depends-on.source-exp.result-type);
end;

define method optimize (component :: <component>, call :: <mv-call>) => ();
  let cluster = call.depends-on.dependent-next.source-exp;
  if (maybe-expand-cluster(component, cluster))
    change-call-kind(component, call, <unknown-call>);
  else
    let func = call.depends-on.source-exp;
    if (instance?(func, <exit-function>))
      maybe-expand-exit-function(component, call, func);
    end;
  end;
end;

define method maybe-expand-exit-function
    (component :: <component>, call :: <abstract-call>,
     func :: <exit-function>)
    => ();
  // Change the call into a pitcher and an exit.
  let call-dependency = call.dependents;
  let assign = call-dependency.dependent;
  let catcher = func.catcher;
  let args = call.depends-on.dependent-next;
  let pitcher = make(<pitcher>, catcher: catcher, next: catcher.pitchers,
		     depends-on: args, dependents: call-dependency);
  catcher.pitchers := pitcher;
  remove-dependency-from-source(component, call.depends-on);
  for (dep = args then dep.dependent-next,
       while: dep)
    dep.dependent := pitcher;
  end;
  call-dependency.source-exp := pitcher;
  queue-dependent(component, assign);
  queue-dependent(component, pitcher);
  insert-exit-after(component, assign, catcher.target-region);
  
end;


// Primitive and other magic operator optimization

define method optimize (component :: <component>, primitive :: <primitive>)
    => ();
  let deriver = element($primitive-type-derivers, primitive.name, default: #f);
  if (deriver)
    let type = deriver(component, primitive);
    maybe-restrict-type(component, primitive, type);
  end;
  // ### Should have some general purpose way to transform primitives.
  if (primitive.name == #"values")
    let assign = primitive.dependents.dependent;
    let defns = assign.defines;
    unless (defns & instance?(defns.var-info, <values-cluster-info>))
      let builder = make-builder(component);
      let next-var = #f;
      for (var = defns then next-var,
	   val-dep = primitive.depends-on
	     then val-dep & val-dep.dependent-next,
	   while: var)
	next-var := var.definer-next;
	var.definer-next := #f;
	build-assignment(builder, assign.policy, assign.source-location, var,
			 if (val-dep)
			   val-dep.source-exp;
			 else
			   make-literal-constant(builder,
						 make(<literal-false>));
			 end);
      end;
      assign.defines := #f;
      // Insert the spred out assignments.
      insert-after(component, assign, builder.builder-result);
      // Nuke the original assignment.
      delete-and-unlink-assignment(component, assign);
    end;
  end;
end;

define method optimize (component :: <component>, prologue :: <prologue>)
    => ();
  let types = make(<stretchy-vector>);
  for (var = prologue.dependents.dependent.defines then var.definer-next,
       while: var)
    add!(types, var.var-info.asserted-type);
  end;
  maybe-restrict-type(component, prologue,
		      make-values-ctype(as(<list>, types), #f));
end;

define method optimize (component :: <component>, catcher :: <catcher>)
    => ();
  // If there is still an exit function, there isn't much we can do.
  unless (catcher.exit-function)
    // Compute the result type of the catcher by unioning all the pitchers.
    let catcher-home = home-lambda(catcher);
    for (pitcher = catcher.pitchers then pitcher.pitcher-next,
	 all-local? = #t
	   then all-local? & home-lambda(pitcher) == catcher-home,
	 result-type = empty-ctype()
	   then values-type-union(result-type, pitcher.pitched-type),
	   while: pitcher)
    finally
      if (all-local?)
	replace-catcher-and-pitchers(component, catcher);
      else
	maybe-restrict-type(component, catcher, result-type);
      end;
    end;
  end;
end;

define method optimize (component :: <component>, pitcher :: <pitcher>) => ();
  let args = pitcher.depends-on;
  let type
    = if (args & instance?(args.source-exp, <abstract-variable>)
	    & instance?(args.source-exp.var-info, <values-cluster-info>))
	args.source-exp.derived-type;
      else
	for (dep = args then dep.dependent-next,
	     types = #() then pair(dep.source-exp.derived-type, types),
	     while: dep)
	finally
	  make-values-ctype(reverse!(types), #f);
	end;
      end;
  let old-type = pitcher.pitched-type;
  if (~values-subtype?(old-type, type) & values-subtype?(type, old-type))
    pitcher.pitched-type := type;
    queue-dependent(component, pitcher.catcher);
  end;
end;


define method replace-catcher-and-pitchers
    (component :: <component>, catcher :: <catcher>) => ();
  // Okay, we are doing a transfer local to this lambda.  So where we had:
  //   () := pitcher(args....)
  //   exit
  //   ...
  //   vars... := catcher()
  // we want to convert it into:
  //   temps := values(args...)
  //   exit
  //   ...
  //   vars := values(temps...)
  // Except that if we are pitching/catching a cluster, we don't want to
  // call values.

  // First, fix up the catcher.
  let builder = make-builder(component);
  let catcher-dep = catcher.dependents;
  let catcher-assign = catcher-dep.dependent;
  let vars = catcher-assign.defines;
  let (temps, temps-expr)
    = if (vars & instance?(vars.var-info, <values-cluster-info>))
	// We are catching a cluster.
	let cluster = make-values-cluster(builder, vars.var-info.debug-name,
					  vars.var-info.asserted-type);
	values(cluster, cluster);
      else
	let temps = make(<stretchy-vector>);
	for (var = vars then var.definer-next,
	     while: var)
	  add!(temps,
	       make-local-var(builder, var.var-info.debug-name,
			      vars.var-info.asserted-type));
	end;
	let list = as(<list>, temps);
	values(list, make-primitive-operation(builder, #"values", list));
      end;

  // Change the catcher assignment to reference the temps.
  catcher-dep.source-exp := temps-expr;
  temps-expr.dependents := catcher-dep;
  catcher.dependents := #f;
  queue-dependent(component, catcher-assign);

  // Flush the catcher.
  delete-dependent(component, catcher);
  catcher.target-region.catcher := #f;

  for (pitcher = catcher.pitchers then pitcher.pitcher-next,
       while: pitcher)
    // Extract the args from the pitcher.
    let arg-deps = pitcher.depends-on;
    let args
      = if (arg-deps & instance?(arg-deps.source-exp, <abstract-variable>)
	      & instance?(arg-deps.source-exp.var-info, <values-cluster-info>))
	  // We are pitching a cluster.
	  arg-deps.source-exp;
	else
	  let args = make(<stretchy-vector>);
	  for (dep = arg-deps then dep.dependent-next,
	       while: dep)
	    add!(args, dep.source-exp);
	  end;
	  make-primitive-operation(builder, #"values", as(<list>, args));
	end;
    // Assign the temps from the args, insert that assignment just before
    // the pitcher, and then delete the pitcher.
    let pitcher-assign = pitcher.dependents.dependent;
    build-assignment(builder, pitcher-assign.policy,
		     pitcher-assign.source-location, temps, args);
    insert-before(component, pitcher-assign, builder-result(builder));
    // Deleting the assignment causes the pitcher to be freed up and
    // queued the catcher for reoptimization.
    delete-and-unlink-assignment(component, pitcher-assign);
  end;

  // Now if there are no exits, flush the block.
  let target = catcher.target-region;
  unless (target.exits)
    replace-subregion(component, target.parent, target, target.body);
  end;
end;


// Function optimization

define method optimize (component :: <component>, lambda :: <lambda>)
    => ();
  let results = lambda.depends-on;
  if (results & instance?(results.source-exp.var-info, <values-cluster-info>))
    // We have to restrict the result type first, otherwise the single
    // values cluster might be expanded away and we would end up just using
    // the first value's type.
    maybe-restrict-result-type(component, lambda,
			       results.source-exp.derived-type);
    if (maybe-expand-cluster(component, results.source-exp))
      queue-dependents(component, lambda);
    end;
  else
    let types = make(<stretchy-vector>);
    for (dep = results then dep.dependent-next,
	 while: dep)
      add!(types, dep.source-exp.derived-type);
    end;
    maybe-restrict-result-type(component, lambda,
			       make-values-ctype(as(<list>, types), #f));
  end;

  // If there is exactly one reference and that reference is the function
  // in a local call, let convert the lambda.
  let dependents = lambda.dependents;
  if (dependents & dependents.source-next == #f)
    let dependent = dependents.dependent;
    if (instance?(dependent, <local-call>)
	  & dependent.depends-on == dependents)
      let-convert(component, lambda);
    end;
  end;
end;

define method maybe-restrict-result-type
    (component :: <component>, lambda :: <lambda>, type :: <values-ctype>)
    => ();
  let old-type = lambda.result-type;
  if (~values-subtype?(old-type, type) & values-subtype?(type, old-type))
    lambda.result-type := type;
    queue-dependents(component, lambda);

    if (type == empty-ctype())
      // We don't return.  So flush the return vars.
      for (dep = lambda.depends-on then dep.dependent-next,
	   while: dep)
	remove-dependency-from-source(component, dep);
      end;
      lambda.depends-on := #f;
    end;
  end;
end;    

define method maybe-expand-cluster
    (component :: <component>, cluster :: <abstract-variable>)
    => did-anything? :: <boolean>;
  if (fixed-number-of-values?(cluster.derived-type))
    unless (cluster.dependents)
      error("Trying to expand a cluster that isn't being used?");
    end;
    if (cluster.dependents.source-next)
      error("Trying to expand a cluster that is in more than one place?");
    end;
    expand-cluster(component, cluster);
    #t;
  else
    #f;
  end;
end;

define method expand-cluster 
    (component :: <component>, cluster :: <ssa-variable>) => ();
  let cluster-dependency = cluster.dependents;
  let target = cluster-dependency.dependent;
  let assign = cluster.definer;
  let new-defines = #f;
  let new-depends-on = cluster-dependency.dependent-next;
  for (index from cluster.derived-type.min-values - 1 to 0 by -1)
    let debug-name = as(<symbol>, format-to-string("result%d", index));
    let var-info = make(<local-var-info>, debug-name: debug-name,
			asserted-type: object-ctype());
    let var = make(<ssa-variable>, var-info: var-info,
		   definer: assign, definer-next: new-defines);
    let dep = make(<dependency>, source-exp: var, source-next: #f,
		   dependent: target, dependent-next: new-depends-on);
    var.dependents := dep;
    new-defines := var;
    new-depends-on := dep;
  end;
  assign.defines := new-defines;
  for (dep = target.depends-on then dep.dependent-next,
       prev = #f then dep,
       until: dep == cluster-dependency)
  finally
    if (prev)
      prev.dependent-next := new-depends-on;
    else
      target.depends-on := new-depends-on;
    end;
  end;
  queue-dependent(component, assign);
  let assign-source = assign.depends-on.source-exp;
  if (instance?(assign-source, <primitive>)
	& assign-source.name == #"values")
    queue-dependent(component, assign-source);
  end;
end;

define method expand-cluster 
    (component :: <component>, cluster :: <initial-variable>) => ();
  let cluster-dependency = cluster.dependents;
  let target = cluster-dependency.dependent;
  let assigns = map(definer, cluster.definitions);
  let new-defines = make(<list>, size: cluster.definitions.size, fill: #f);
  let new-depends-on = cluster-dependency.dependent-next;
  for (index from cluster.derived-type.min-values - 1 to 0 by -1)
    let debug-name = as(<symbol>, format-to-string("result%d", index));
    let var-info = make(<local-var-info>, debug-name: debug-name,
			asserted-type: object-ctype());
    let var = make(<initial-variable>, var-info: var-info);
    let defns = map(method (assign, next-define)
		      let defn = make(<initial-definition>, var-info: var-info,
				      definition: var, definer: assign,
				      definer-next: next-define,
				      next-initial-definition:
					component.initial-definitions);
		      component.initial-definitions := defn;
		      defn;
		    end,
		    assigns, new-defines);
    let dep = make(<dependency>, source-exp: var, source-next: #f,
		   dependent: target, dependent-next: new-depends-on);
    var.dependents := dep;
    new-defines := defns;
    new-depends-on := dep;
  end;
  for (assign in assigns, defn in new-defines)
    assign.defines := defn;
  end;
  for (dep = target.depends-on then dep.dependent-next,
       prev = #f then dep,
       until: dep == cluster-dependency)
  finally
    if (prev)
      prev.dependent-next := new-depends-on;
    else
      target.depends-on := new-depends-on;
    end;
  end;
  for (assign in assigns)
    queue-dependent(component, assign);
    let assign-source = assign.depends-on.source-exp;
    if (instance?(assign-source, <primitive>)
	  & assign-source.name == #"values")
      queue-dependent(component, assign-source);
    end;
  end;
end;

define method let-convert (component :: <component>, lambda :: <lambda>) => ();
  let call :: <local-call> = lambda.dependents.dependent;
  let call-assign :: <assignment> = call.dependents.dependent;

  let builder = make-builder(component);

  // Define a bunch of temporaries from the call args just before the call.
  let temps = make(<stretchy-vector>);
  begin
    let policy = call-assign.policy;
    let source = call-assign.source-location;
    for (dep = call.depends-on.dependent-next then dep.dependent-next,
	 param = lambda.prologue.dependents.dependent.defines
	   then param.definer-next,
	 while: dep & param)
      let var-info = param.var-info;
      let temp = make-local-var(builder, var-info.debug-name,
				var-info.asserted-type);
      add!(temps, temp);
      build-assignment(builder, policy, source, temp, dep.source-exp);
    finally
      if (dep | param)
	error("Different number of parameters and arguments in known call?");
      end;
    end;
    insert-before(component, call-assign, builder-result(builder));
  end;
  let temps = as(<list>, temps);

  // Replace the prologue with the temps.
  begin
    let op = make-primitive-operation(builder, #"values", temps);
    let prologue = lambda.prologue;
    let dep = prologue.dependents;
    dep.source-exp := op;
    op.dependents := dep;
    delete-dependent(component, prologue);
    queue-dependent(component, op);
  end;

  // For each self-tail-call, change it into an assignment of the arg temps.
  if (lambda.self-tail-calls)
    // But first, peel off the temps that correspond to closure vars.
    for (closure-var = lambda.environment.closure-vars
	   then closure-var.closure-next,
	 temps = temps then temps.tail,
	 while: closure-var)
    finally
      for (self-tail-call = lambda.self-tail-calls
	     then self-tail-call.next-self-tail-call,
	   while: self-tail-call)
	let assign = self-tail-call.dependents.dependent;
	for (dep = self-tail-call.depends-on then dep.dependent-next,
	     args = #() then pair(dep.source-exp, args),
	     while: dep)
	finally
	  let op = make-primitive-operation(builder, #"values",
					    reverse!(args));
	  build-assignment(builder, assign.policy, assign.source-location,
			   temps, op);
	  insert-before(component, assign, builder-result(builder));
	  delete-and-unlink-assignment(component, assign);
	end;
      end;
    end;
  end;

  // Change the call to a reference to the results.
  let results = lambda.depends-on;
  if (results & instance?(results.source-exp.var-info, <values-cluster-info>))
    results.dependent := call-assign;
    call-assign.depends-on := results;
  else
    // Make a values operation for the lambda results.
    let values-op = make(<primitive>, derived-type: lambda.result-type,
			 dependents: call.dependents, name: #"values",
			 depends-on: results);
    // Change the results to feed into the values-op
    for (dep = results then dep.dependent-next,
	 while: dep)
      dep.dependent := values-op;
    end;
    for (dep = call.dependents then dep.source-next,
	 while: dep)
      dep.source-exp := values-op;
    end;
    queue-dependent(component, values-op);
    call-assign.depends-on.source-exp := values-op;
  end;
  queue-dependent(component, call-assign);

  // Queue the catchers for blocks in the new home that are exited to from the
  // lambda's body.
  queue-catchers(component, home-lambda(call-assign), lambda.body);

  // Insert the lambda body before the call assignment (which is now the result
  // assignment).
  insert-before(component, call-assign, lambda.body);

  // Delete the lambda.
  component.all-methods := remove!(component.all-methods, lambda);
end;

define method queue-catchers
    (component :: <component>, home :: <lambda>, region :: <simple-region>)
    => ();
end;

define method queue-catchers
    (component :: <component>, home :: <lambda>, region :: <compound-region>)
    => ();
  for (subregion in region.regions)
    queue-catchers(component, home, subregion);
  end;
end;

define method queue-catchers
    (component :: <component>, home :: <lambda>, region :: <if-region>)
    => ();
  queue-catchers(component, home, region.then-region);
  queue-catchers(component, home, region.else-region);
end;

define method queue-catchers
    (component :: <component>, home :: <lambda>, region :: <body-region>)
    => ();
  queue-catchers(component, home, region.body);
end;

define method queue-catchers
    (component :: <component>, home :: <lambda>, region :: <exit>)
    => ();
  let target = region.block-of;
  if (home-lambda(target) == home)
    queue-dependent(component, target.catcher);
  end;
end;



// If optimizations.

define method optimize (component :: <component>, if-region :: <if-region>)
    => ();
  let condition-type = if-region.depends-on.source-exp.derived-type;
  let false = dylan-value(#"<false>");
  if (csubtype?(condition-type, false))
    replace-if-with(component, if-region, if-region.else-region);
    delete-stuff-in(component, if-region.then-region);
  elseif (~ctypes-intersect?(false, condition-type))
    replace-if-with(component, if-region, if-region.then-region);
    delete-stuff-in(component, if-region.else-region);
  elseif (instance?(if-region.then-region, <empty-region>)
	    & instance?(if-region.else-region, <empty-region>))
    replace-if-with(component, if-region, make(<empty-region>));
  end;
end;

define method replace-if-with
    (component :: <component>, if-region :: <if-region>, with :: <region>)
    => ();
  let builder = make-builder(component);
  build-assignment(builder, $Default-Policy, if-region.source-location,
		   #(), if-region.depends-on.source-exp);
  build-region(builder, with);
  replace-subregion(component, if-region.parent, if-region,
		    builder-result(builder));
  delete-dependent(component, if-region);
end;



// Type utilities.

define method queue-dependent
    (component :: <component>, dependent :: <dependent-mixin>) => ();
  if (dependent.queue-next == #"absent")
    dependent.queue-next := component.reoptimize-queue;
    component.reoptimize-queue := dependent;
  end;
end;

define method queue-dependents
    (component :: <component>, expr :: <expression>) => ();
  for (dependency = expr.dependents then dependency.source-next,
       while: dependency)
    queue-dependent(component, dependency.dependent);
  end;
end;

define method assert-type
    (component :: <component>, before :: <assignment>,
     dependent :: <dependency>, type :: <ctype>)
    => ();
  let source = dependent.source-exp;
  unless (csubtype?(source.derived-type, type))
    let builder = make-builder(component);
    let temp = make-ssa-var(builder, #"temp", type);
    build-assignment(builder, before.policy, before.source-location,
		     temp, source);
    for (dep = source.dependents then dep.source-next,
	 prev = #f then dep,
	 until: dep == dependent)
    finally
      if (prev)
	prev.source-next := dep.source-next;
      else
	source.dependents := dep.source-next;
      end;
    end;
    dependent.source-exp := temp;
    temp.dependents := dependent;
    dependent.source-next := #f;
    insert-before(component, before, builder-result(builder));
  end;
end;

define method maybe-restrict-type
    (component :: <component>, expr :: <expression>, type :: <values-ctype>)
    => ();
  let old-type = expr.derived-type;
  if (~values-subtype?(old-type, type) & values-subtype?(type, old-type))
    expr.derived-type := type;
    if (instance?(expr, <initial-definition>))
      let var = expr.definition-of;
      if (instance?(var, <initial-variable>))
	block (return)
	  let var-type = empty-ctype();
	  for (defn in var.definitions)
	    let (res, win) = values-type-union(var-type, defn.derived-type);
	    if (win)
	      var-type := res;
	    else
	      return();
	    end;
	  finally
	    maybe-restrict-type(component, var, var-type);
	  end;
	end;
      end;
    end;
    queue-dependents(component, expr);
  end;
end;

define method maybe-restrict-type
    (component :: <component>, var :: <abstract-variable>,
     type :: <values-ctype>, #next next-method)
    => ();
  let var-info = var.var-info;
  next-method(component, var,
	      if (instance?(var-info, <values-cluster-info>))
		values-type-intersection(type, var-info.asserted-type);
	      else
		ctype-intersection(defaulted-first-type(type),
				   var-info.asserted-type);
	      end);
end;

define method maybe-restrict-type
    (component :: <component>, var :: <definition-site-variable>,
     type :: <values-ctype>, #next next-method)
    => ();
  if (var.needs-type-check?
	& values-subtype?(type, var.var-info.asserted-type))
    var.needs-type-check? := #f;
    queue-dependent(component, var.definer);
  end;
  next-method();
end;

define method defaulted-first-type (ctype :: <ctype>) => res :: <ctype>;
  ctype;
end;

define method defaulted-first-type (ctype :: <values-ctype>) => res :: <ctype>;
  let positionals = ctype.positional-types;
  if (positionals == #())
    ctype-union(ctype.rest-value-type, dylan-value(#"<false>"));
  elseif (zero?(ctype.min-values))
    ctype-union(positionals[0], dylan-value(#"<false>"));    
  else
    positionals[0];
  end;
end;

define method fixed-number-of-values? (ctype :: <ctype>) => res :: <boolean>;
  #t;
end;

define method fixed-number-of-values?
    (ctype :: <values-ctype>) => res :: <boolean>;
  ctype.min-values == ctype.positional-types.size
    & ctype.rest-value-type == empty-ctype();
end;


// Type derivers for various primitives.

define constant $primitive-type-derivers = make(<object-table>);

define method define-primitive-deriver
    (name :: <symbol>, deriver :: <function>)
    => ();
  $primitive-type-derivers[name] := deriver;
end;


define method values-type-deriver
    (component :: <component>, primitive :: <primitive>)
    => res :: <values-ctype>;
  for (dep = primitive.depends-on then dep.dependent-next,
       types = #() then pair(dep.source-exp.derived-type, types),
       while: dep)
  finally
    make-values-ctype(reverse!(types), #f);
  end;
end;

define-primitive-deriver(#"values", values-type-deriver);


define method fixnum-args-boolean-result
    (component :: <component>, primitive :: <primitive>)
    => res :: <values-ctype>;
  let fixed-int = dylan-value(#"<fixed-integer>");
  let assign = primitive.dependents.dependent;
  for (dep = primitive.depends-on then dep.dependent-next,
       while: dep)
    assert-type(component, assign, dep, fixed-int);
  end;
  dylan-value(#"<boolean>");
end;

define-primitive-deriver(#"fixnum-=", fixnum-args-boolean-result);
define-primitive-deriver(#"fixnum-<", fixnum-args-boolean-result);

define method fixnum-args-fixnum-result
    (component :: <component>, primitive :: <primitive>)
    => res :: <values-ctype>;
  let fixed-int = dylan-value(#"<fixed-integer>");
  let assign = primitive.dependents.dependent;
  for (dep = primitive.depends-on then dep.dependent-next,
       while: dep)
    assert-type(component, assign, dep, fixed-int);
  end;
  fixed-int;
end;

for (name in #[#"fixnum-+", #"fixnum-*", #"fixnum--", #"fixnum-negative",
		 #"fixnum-logior", #"fixnum-logxor", #"fixnum-logand",
		 #"fixnum-lognot", #"fixnum-ash"])
  define-primitive-deriver(name, fixnum-args-fixnum-result);
end;

define method fixnum-args-two-fixnums-result
    (component :: <component>, primitive :: <primitive>)
    => res :: <values-ctype>;
  let fixed-int = dylan-value(#"<fixed-integer>");
  let assign = primitive.dependents.dependent;
  for (dep = primitive.depends-on then dep.dependent-next,
       while: dep)
    assert-type(component, assign, dep, fixed-int);
  end;
  make-values-ctype(list(fixed-int, fixed-int), #f);
end;

for (name in #[#"fixnum-floor/", #"fixnum-ceiling/", #"fixnum-round/",
		 #"fixnum-truncate/"])
  define-primitive-deriver(name, fixnum-args-two-fixnums-result);
end;


// Tail call identification.


define method identify-tail-calls (component :: <component>) => ();
  for (lambda in component.all-methods)
    identify-tail-calls-in(component, lambda, lambda.depends-on, lambda.body);
  end;
end;

  
define method identify-tail-calls-in
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), region :: <simple-region>)
    => ();
  block (return)
    for (assign = region.last-assign then assign.prev-op,
	 while: assign)
      for (result = results then result.dependent-next,
	   defn = assign.defines then defn.definer-next,
	   while: result | defn)
	if (~result | ~defn | defn.needs-type-check?
	      | ~definition-for?(defn, result.source-exp))
	  return();
	end;
      end;
      let expr = assign.depends-on.source-exp;
      if (instance?(expr, union(<known-call>, <local-call>)))
	if (expr.depends-on.source-exp == home)
	  // It's a self tail call.
	  convert-self-tail-call(component, home, expr);
	end;
	return();
      end;
      if (assign.defines
	    & instance?(assign.defines.var-info, <values-cluster-info>))
	// Want to return a cluster.
	if (instance?(expr, <abstract-variable>)
	      & instance?(expr.var-info, <values-cluster-info>))
	  results := assign.depends-on;
	else
	  return();
	end;
      else
	// Want to return a specific number of values.
	if (instance?(expr, <abstract-variable>))
	  if (assign.defines & assign.defines.definer-next == #f
		& ~instance?(expr.var-info, <values-cluster-info>))
	    results := assign.depends-on;
	  else
	    return();
	  end;
	elseif (instance?(expr, <primitive>) & expr.name == #"values")
	  for (defn = assign.defines then defn.definer-next,
	       dep = expr.depends-on then dep.dependent-next,
	       while: defn & dep)
	  finally
	    if (defn | dep)
	      return();
	    else
	      results := expr.depends-on;
	    end;
	  end;
	else
	  return();
	end;
      end;
    finally
      identify-tail-calls-before(component, home, results,
				 region.parent, region);
    end;
  end;
end;

define method identify-tail-calls-in
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), region :: <compound-region>)
    => ();
  identify-tail-calls-in(component, home, results, region.regions.last);
end;

define method identify-tail-calls-in
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), region :: <empty-region>)
    => ();
  identify-tail-calls-before(component, home, results, region.parent, region);
end;

define method identify-tail-calls-in
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), region :: <if-region>)
    => ();
  identify-tail-calls-in(component, home, results, region.then-region);
  identify-tail-calls-in(component, home, results, region.else-region);
end;
  
define method identify-tail-calls-in
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), region :: <loop-region>)
    => ();
end;

define method identify-tail-calls-in
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), region :: <block-region>)
    => ();
  for (exit = region.exits then exit.next-exit,
       while: exit)
    if (home-lambda(exit) == home)
      identify-tail-calls-before(component, home, results,
				 exit.parent, exit);
    end;
  end;
end;

define method identify-tail-calls-in
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), region :: <exit>)
    => ();
end;


define generic definition-for?
    (defn :: <definition-site-variable>, var :: <abstract-variable>)
    => res :: <boolean>;

define method definition-for?
    (defn :: <ssa-variable>, var :: <abstract-variable>)
    => res :: <boolean>;
  defn == var;
end;

define method definition-for?
    (defn :: <initial-definition>, var :: <abstract-variable>)
    => res :: <boolean>;
  defn.definition-of == var;
end;


define generic identify-tail-calls-before
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), in :: <region>, before :: <region>)
    => ();

define method identify-tail-calls-before
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), in :: <region>,
     before :: <region>)
    => ();
  identify-tail-calls-before(component, home, results, in.parent, in);
end;

define method identify-tail-calls-before
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), in :: <compound-region>,
     before :: <region>)
    => ();
  block (return)
    for (subregion in in.regions,
	 prev = #f then subregion)
      if (subregion == before)
	if (prev)
	  identify-tail-calls-in(component, home, results, prev);
	else
	  identify-tail-calls-before(component, home, results, in.parent, in);
	end;
	return();
      end;
    end;
  end;
end;

define method identify-tail-calls-before
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), in :: <if-region>,
     before :: <region>)
    => ();
end;

define method identify-tail-calls-before
    (component :: <component>, home :: <lambda>,
     results :: false-or(<dependency>), in :: <method-region>,
     before :: <region>)
    => ();
end;


define method convert-self-tail-call
    (component :: <component>, func :: <lambda>, call :: <abstract-call>)
    => ();
  // Set up the wrapper loop and blocks.
  unless (func.self-call-block)
    let builder = make-builder(component);
    let source = func.source-location;
    let return-block = build-block-body(builder, $Default-Policy, source);
    build-loop-body(builder, $Default-Policy, source);
    func.self-call-block := build-block-body(builder, $Default-Policy, source);
    build-region(builder, func.body);
    build-exit(builder, $Default-Policy, source, return-block);
    end-body(builder); // end of the self call block
    end-body(builder); // end of the loop
    end-body(builder); // end of return block
    replace-subregion(component, func, func.body, builder-result(builder));
  end;
  // Change the call into a self-tail-call operation.
  let op = make(<self-tail-call>, dependents: call.dependents,
		depends-on: call.depends-on.dependent-next,
		next-self-tail-call: func.self-tail-calls, of: func);
  func.self-tail-calls := op;
  remove-dependency-from-source(component, call.depends-on);
  for (dep = op.depends-on then dep.dependent-next,
       while: dep)
    dep.dependent := op;
  end;
  let assign-dep = call.dependents;
  assign-dep.source-exp := op;
  assert(~assign-dep.source-next);
  // Insert the exit to self-call-block after the self-tail-call assignment.
  let assign = assign-dep.dependent;
  insert-exit-after(component, assign, func.self-call-block);
  // Delete the definitions for the assignment.
  for (defn = assign.defines then defn.definer-next,
       while: defn)
    delete-definition(component, defn);
  end;
  assign.defines := #f;
  // Queue the assignment and self-tail-call operation.
  queue-dependent(component, assign);
  queue-dependent(component, op);
end;


// Cheesy type check stuff.


define method add-type-checks (component :: <component>) => ();
  for (lambda in component.all-methods)
    add-type-checks-aux(component, lambda);
  end;
end;

define method add-type-checks-aux
    (component :: <component>, region :: <simple-region>) => ();
  let next-assign = #f;
  for (assign = region.first-assign then next-assign,
       while: assign)
    let builder = #f;
    next-assign := assign.next-op;
    for (defn = assign.defines then defn.definer-next,
	 prev = #f then defn,
	 while: defn)
      if (defn.needs-type-check?)
	// Make a temp to hold the unchecked value.
	let temp = if (instance?(defn.var-info, <values-cluster-info>))
		     error("values cluster needs a type check?");
		   else
		     make(<ssa-variable>,
			  definer: assign,
			  definer-next: defn.definer-next,
			  var-info: make(<local-var-info>,
					 debug-name: defn.var-info.debug-name,
					 asserted-type: object-ctype()));
		   end;
	// Link the temp in in place of this definition.
	if (prev)
	  prev.definer-next := temp;
	else
	  assign.defines := temp;
	end;
	// Make the builder if we haven't already.
	unless (builder)
	  builder := make-builder(component);
	end;
	// Make the check type operation.
	let asserted-type = defn.var-info.asserted-type;
	let check = make-check-type-operation(builder, temp,
					      make-literal-constant
						(builder, asserted-type));
	// Assign the type checked value to the real var.
	defn.definer-next := #f;
	build-assignment(builder, assign.policy, assign.source-location,
			 defn, check);
	// Seed the derived type of the check-type call.
	let cur-type = assign.depends-on.source-exp.derived-type;
	let cur-type-positionals = cur-type.positional-types;
	let (checked-type, precise?)
	  = ctype-intersection(asserted-type, defaulted-first-type(cur-type));
	maybe-restrict-type(component, check,
			    if (precise?)
			      checked-type;
			    else
			      asserted-type;
			    end);
	// Queue the assignment for reoptimization.
	queue-dependent(component, assign);
	// Change defn to temp so that the loop steps correctly.
	defn := temp;
      end;
    end;
    if (builder)
      insert-after(component, assign, builder-result(builder));
    end;
  end;
end;

// duplicated from fer-convert because I don't want to figure out how to
// import them from there.
// 
define method dylan-defn-leaf (builder :: <fer-builder>, name :: <symbol>)
    => res :: <leaf>;
  make-definition-leaf(builder, dylan-defn(name))
    | error("%s undefined?", name);
end;

define method make-check-type-operation (builder :: <fer-builder>,
					 value-leaf :: <leaf>,
					 type-leaf :: <leaf>)
    => res :: <operation>;
  make-operation(builder,
		 list(dylan-defn-leaf(builder, #"check-type"),
		      value-leaf,
		      type-leaf));
end method;


define method add-type-checks-aux
    (component :: <component>, region :: <compound-region>) => ();
  for (subregion in region.regions)
    add-type-checks-aux(component, subregion);
  end;
end;

define method add-type-checks-aux
    (component :: <component>, region :: <if-region>) => ();
  add-type-checks-aux(component, region.then-region);
  add-type-checks-aux(component, region.else-region);
end;

define method add-type-checks-aux
    (component :: <component>, region :: <body-region>) => ();
  add-type-checks-aux(component, region.body);
end;

define method add-type-checks-aux
    (component :: <component>, region :: <exit>) => ();
end;



// Environment analysis

define method environment-analysis (component :: <component>) => ();
  let lets = component.all-lets;
  component.all-lets := #f;
  for (l = lets then l.let-next, while: l)
    unless (l.queue-next == #"deleted")
      let home = home-lambda(l);
      let next = #f;
      for (var = l.defines then next,
	   while: var)
	next := var.definer-next;
	maybe-close-over(component, var, home);
      end;
    end;
  end;
end;

define method home-lambda (op :: <operation>) => home :: <lambda>;
  home-lambda(op.dependents.dependent);
end;

define method home-lambda (assign :: <assignment>) => home :: <lambda>;
  home-lambda(assign.region);
end;

define method home-lambda (region :: <region>) => home :: <lambda>;
  home-lambda(region.parent);
end;

define method home-lambda (lambda :: <lambda>) => home :: <lambda>;
  lambda;
end;

define method maybe-close-over
    (component :: <component>, var :: <ssa-variable>, home :: <lambda>) => ();
  let orig-dependents = var.dependents;
  var.dependents := #f;
  let next = #f;
  for (dep = orig-dependents then next,
       while: dep)
    next := dep.source-next;
    let ref = dep.dependent;
    let ref-lambda = home-lambda(ref);
    let copy = find-in-environment(component, ref-lambda, var, home);
    dep.source-next := copy.dependents;
    copy.dependents := dep;
    dep.source-exp := copy;
  end;
end;

define method find-in-environment
    (component :: <component>, lambda :: <lambda>,
     var :: <ssa-variable>, home :: <lambda>)
    => copy :: <ssa-variable>;
  if (lambda == home)
    var;
  else
    block (return)
      for (closure = lambda.environment.closure-vars then closure.closure-next,
	   while: closure)
	if (closure.original-var == var)
	  return(closure.copy-var);
	end;
      end;
      let prologue = lambda.prologue;
      let assign = prologue.dependents.dependent;
      let copy = make(<ssa-variable>, var-info: var.var-info, definer: assign,
		      definer-next: assign.defines,
		      derived-type: var.derived-type);
      assign.defines := copy;
      lambda.environment.closure-vars
	:= make(<closure-var>, original: var, copy: copy,
		next: lambda.environment.closure-vars);
      prologue.derived-type := wild-ctype();
      for (call-dep = lambda.dependents then call-dep.source-next,
	   while: call-dep)
	let call = call-dep.dependent;
	let var-in-caller
	  = find-in-environment(component, home-lambda(call), var, home);
	let func-dep = call.depends-on;
	let new-dep = make(<dependency>, source-exp: var-in-caller,
			   source-next: var-in-caller.dependents,
			   dependent: call,
			   dependent-next: func-dep.dependent-next);
	var-in-caller.dependents := new-dep;
	func-dep.dependent-next := new-dep;
	queue-dependent(component, call);
      end;
      queue-dependent(component, prologue);
      copy;
    end;
  end;
end;

define method maybe-close-over
    (component :: <component>, defn :: <initial-definition>, home :: <lambda>)
    => ();
  let var = defn.definition-of;
  if (block (return)
	for (defn in var.definitions)
	  unless (home-lambda(defn.definer) == home)
	    return(#t);
	  end;
	end;
	for (dep = var.dependents then dep.source-next,
	     while: dep)
	  unless (home-lambda(dep.dependent) == home)
	    return(#t);
	  end;
	end;
	#f;
      end)
    let value-cell-type = dylan-value(#"<value-cell>");
    let builder = make-builder(component);
    let value-cell = make(<ssa-variable>,
			  var-info: make(<lexical-var-info>,
					 debug-name: var.var-info.debug-name,
					 asserted-type: value-cell-type,
					 source-location:
					   var.var-info.source-location),
			  derived-type: value-cell-type);
    let value-setter = dylan-defn-leaf(builder, #"value-setter");
    for (defn in var.definitions)
      let temp = make-ssa-var(builder, var.var-info.debug-name,
			      defn.derived-type);
      let assign = defn.definer;
      for (other = assign.defines then other.definer-next,
	   prev = #f then other,
	   until: other == defn)
      finally
	if (prev)
	  prev.definer-next := temp;
	else
	  assign.defines := temp;
	end;
	temp.definer-next := other.definer-next;
      end;
      temp.definer := assign;
      select (defn.definer by instance?)
	<let-assignment> =>
	  let op
	    = make-operation(builder,
			     list(dylan-defn-leaf(builder, #"make"),
				  make-literal-constant
				    (builder, value-cell-type),
				  make-literal-constant
				    (builder,
				     make(<literal-symbol>, value: #"value")),
				  temp));
	  op.derived-type := value-cell-type;
	  build-assignment
	    (builder, assign.policy, assign.source-location, value-cell, op);
	<set-assignment> =>
	  build-assignment
	    (builder, assign.policy, assign.source-location, #(),
	     make-operation(builder, list(value-setter, temp, value-cell)));
      end;
      insert-after(component, assign, builder-result(builder));
      queue-dependent(component, assign);
    end;
    let value = dylan-defn-leaf(builder, #"value");
    let next = #f;
    for (dep = var.dependents then next,
	 while: dep)
      next := dep.source-next;
      let temp = make-ssa-var(builder, var.var-info.debug-name,
			      var.derived-type);
      dep.source-exp := temp;
      temp.dependents := dep;
      dep.source-next := #f;
      let op = make-operation(builder, list(value, value-cell));
      op.derived-type := var.derived-type;
      build-assignment(builder, $Default-Policy, make(<source-location>),
		       temp, op);
      insert-before(component, dep.dependent, builder-result(builder));
    end;
    maybe-close-over(component, value-cell, home);
  end;
end;



// Deletion code.

define method delete-dependent
    (component :: <component>, dependent :: <dependent-mixin>) => ();
  //
  // Remove our dependency from whatever we depend on.
  for (dep = dependent.depends-on then dep.dependent-next,
       while: dep)
    remove-dependency-from-source(component, dep);
  end;
  //
  // If we are queued for reoptimization, belay that.
  unless (dependent.queue-next == #"absent")
    for (dep = component.reoptimize-queue then dep.queue-next,
	 prev = #f then dep,
	 until: dep == dependent)
    finally
      if (prev)
	prev.queue-next := dep.queue-next;
      else
	component.reoptimize-queue := dep.queue-next;
      end;
    end;
  end;
  dependent.queue-next := #"deleted";
end;

define method delete-dependent
    (component :: <component>, pitcher :: <pitcher>, #next next-method)
    => ();
  next-method();
  let catcher = pitcher.catcher;
  for (scan = catcher.pitchers then scan.pitcher-next,
       prev = #f then scan,
       until: scan == pitcher)
  finally
    if (prev)
      prev.pitcher-next := pitcher.pitcher-next;
    else
      catcher.pitchers := pitcher.pitcher-next;
    end;
  end;
  queue-dependent(component, catcher);
end;

define method delete-and-unlink-assignment
    (component :: <component>, assignment :: <assignment>) => ();

  // Do everything but the unlinking.
  delete-assignment(component, assignment);

  // Unlink the assignment from region.
  let next = assignment.next-op;
  let prev = assignment.prev-op;
  if (next | prev)
    if (next)
      next.prev-op := prev;
    else
      assignment.region.last-assign := prev;
    end;
    if (prev)
      prev.next-op := next;
    else
      assignment.region.first-assign := next;
    end;
  else
    // It was the only assignment in the region, so flush the region.
    let region = assignment.region;
    replace-subregion(component, region.parent, region, make(<empty-region>));
  end;

  // Set the region to #f to indicate that we are a gonner.
  assignment.region := #f;
end;


define method delete-assignment
    (component :: <component>, assignment :: <assignment>) => ();

  // Clean up the dependent aspects.
  delete-dependent(component, assignment);

  // Nuke the definitions.
  for (var = assignment.defines then var.definer-next,
       while: var)
    delete-definition(component, var);
  end;
end;

define method delete-definition
    (component :: <component>, defn :: <ssa-variable>) => ();
  defn.definer := #f;
end;

define method delete-definition
    (component :: <component>, defn :: <initial-definition>) => ();
  defn.definer := #f;
  let var = defn.definition-of;
  var.definitions := remove!(var.definitions, defn);
  unless (empty?(var.definitions))
    let remaining-defn = var.definitions.first;
    remaining-defn.next-initial-definition := component.initial-definitions;
    component.initial-definitions := remaining-defn;
  end;
end;


define method remove-dependency-from-source
    (component :: <component>, dependency :: <dependency>) => ();
  let source = dependency.source-exp;
  for (dep = source.dependents then dep.source-next,
       prev = #f then dep,
       until: dep == dependency)
  finally
    if (prev)
      prev.source-next := dep.source-next;
    else
      source.dependents := dep.source-next;
    end;
  end;

  // Note that we dropped a dependent in case doing so will trigger
  // some optimization based on the number of definers.
  dropped-dependent(component, source);
end;

define method dropped-dependent
    (component :: <component>, expr :: <expression>) => ();
end;

define method dropped-dependent
    (component :: <component>, op :: <operation>) => ();
  if (op.dependents)
    error("%= had more than one dependent?");
  end;
  delete-dependent(component, op);
end;

define method dropped-dependent
    (component :: <component>, var :: <ssa-variable>) => ();
  // If the variable ended up with no references and doesn't need a type check,
  // queue it for reoptimization so it gets deleted.
  unless (var.dependents | var.needs-type-check?)
    queue-dependent(component, var.definer);
  end;
end;

define method dropped-dependent
    (component :: <component>, lambda :: <lambda>) => ();
  // If the lambda has exactly one reference, queue it for reoptimization so
  // that reference can get let converted.
  if (lambda.dependents & ~lambda.dependents.source-next)
    queue-dependent(component, lambda);
  end;
end;

define method dropped-dependent
    (component :: <component>, exit :: <exit-function>) => ();
  // If we dropped the last reference, clear it out.
  unless (exit.dependents)
    let catcher = exit.catcher;
    catcher.exit-function := #f;
    queue-dependent(component, catcher);
  end;
end;

// insert-exit-after -- internal.
//
// Inserts an exit to the target after the assignment, and deletes everything
// following it in the control flow.  This is the interface to data driven
// dead code deletion.
//
define method insert-exit-after
    (component :: <component>, assignment :: <abstract-assignment>,
     target :: <block-region-mixin>)
    => ();
  let region = assignment.region;
  let region-parent = region.parent;
  let (before, after) = split-after(assignment);
  if (exit-useless?(region-parent, region, target))
    replace-subregion(component, region-parent, region, before);
    after.parent := #f;
    delete-stuff-in(component, after);
  else
    let exit = make(<exit>, block: target, next: target.exits);
    target.exits := exit;
    let new = combine-regions(before, exit);
    replace-subregion(component, region-parent, region, new);
    after.parent := #f;
    delete-stuff-in(component, after);
    delete-stuff-after(component, new, exit);
  end;
end;


define generic exit-useless?
    (from :: <region>, after :: <region>, target :: <block-region-mixin>)
    => res :: <boolean>;

define method exit-useless?
    (from :: <compound-region>, after :: <region>,
     target :: <block-region-mixin>)
    => res :: <boolean>;
  for (regions = from.regions then regions.tail,
       second-to-last = #f then last,
       last = #f then regions.head,
       until: regions == #())
  finally
    if (last == after)
      exit-useless?(from.parent, from, target);
    elseif (second-to-last == after
	      & instance?(last, <exit>)
	      & last.block-of == target)
      #t;
    else
      #f;
    end;
  end;
end;

define method exit-useless?
    (from :: <if-region>, after :: <region>, target :: <block-region-mixin>)
    => res :: <boolean>;
  exit-useless?(from.parent, from, target);
end;

define method exit-useless?
    (from :: <loop-region>, after :: <region>, target :: <block-region-mixin>)
    => res :: <boolean>;
  #f;
end;

define method exit-useless?
    (from :: <block-region>, after :: <region>, target :: <block-region-mixin>)
    => res :: <boolean>;
  from == target | exit-useless?(from.parent, from, target);
end;

define method exit-useless?
    (from :: <method-region>, after :: <region>,
     target :: <block-region-mixin>)
    => res :: <boolean>;
  #f;
end;


define method delete-stuff-in
    (component :: <component>, simple-region :: <simple-region>) => ();
  for (assign = simple-region.first-assign then assign.next-op,
       while: assign)
    delete-assignment(component, assign);
    assign.region := #f;
  end;
end;

define method delete-stuff-in
    (component :: <component>, region :: <compound-region>) => ();
  for (subregion in region.regions)
    delete-stuff-in(component, subregion);
  end;
end;

define method delete-stuff-in
    (component :: <component>, region :: <if-region>) => ();
  delete-dependent(component, region);
  delete-stuff-in(component, region.then-region);
  delete-stuff-in(component, region.else-region);
end;

define method delete-stuff-in
    (component :: <component>, region :: <body-region>) => ();
  delete-stuff-in(component, region.body);
end;

define method delete-stuff-in
    (component :: <component>, region :: <exit>) => ();
  let block-region = region.block-of;
  for (scan = block-region.exits then scan.next-exit,
       prev = #f then scan,
       until: scan == region)
  finally
    let next = region.next-exit;
    if (prev)
      prev.next-exit := next;
    else
      block-region.exits := next;
      unless (next)
	all-exits-gone(component, block-region);
      end;
    end;
  end;
end;


define method all-exits-gone
    (component :: <component>, region :: <component>) => ();
end;

define method all-exits-gone
    (component :: <component>, region :: <block-region>) => ();
  let parent = region.parent;
  if (parent)
    replace-subregion(component, parent, region, region.body);
  end;
end;

define method all-exits-gone
    (component :: <component>, region :: <fer-exit-block-region>,
     #next next-method)
    => ();
  unless (region.catcher & region.catcher.exit-function)
    next-method();
  end;
end;


define method delete-stuff-after
    (component :: <component>, region :: <compound-region>, after :: <region>)
    => ();
  for (remaining = region.regions then remaining.tail,
       until: remaining.head == after)
  finally
    for (subregion in remaining.tail)
      delete-stuff-in(component, subregion);
    end;
    remaining.tail := #();
  end;

  delete-stuff-after(component, region.parent, region);

  if (region.regions.size == 1)
    replace-subregion(component, region.parent, region, region.regions[0]);
  end;
end;

define method delete-stuff-after
    (component :: <component>, region :: <if-region>, after :: <region>)
    => ();
  if (select (after)
	region.then-region => doesnt-return?(region.else-region);
	region.else-region => doesnt-return?(region.then-region);
      end)
    delete-stuff-after(component, region.parent, region);
  end;
end;

define method delete-stuff-after
    (component :: <component>, region :: <loop-region>, after :: <region>)
    => ();
  // There is nothing ``after'' a loop region in the flow of control.
end;

define method delete-stuff-after
    (component :: <component>, region :: <block-region>, after :: <region>)
    => ();
  // There will be at least on exit (or the exit function), so the code
  // after the block is still reachable.
end;

define method delete-stuff-after
    (component :: <component>, lambda :: <lambda>, after :: <region>)
    => ();
  // Deleting the stuff after a lambda means that the function doesn't return.
  // So we change its return type to empty-ctype.
  maybe-restrict-result-type(component, lambda, empty-ctype());
end;


define method doesnt-return? (region :: <simple-region>) => res :: <boolean>;
  #f;
end;

define method doesnt-return? (region :: <compound-region>) => res :: <boolean>;
  doesnt-return?(region.regions.last);
end;

define method doesnt-return? (region :: <empty-region>) => res :: <boolean>;
  #f;
end;

define method doesnt-return? (region :: <if-region>) => res :: <boolean>;
  doesnt-return?(region.then-region) & doesnt-return?(region.else-region);
end;

define method doesnt-return? (region :: <loop-region>) => res :: <boolean>;
  #t;
end;

define method doesnt-return?
    (region :: <fer-exit-block-region>) => res :: <boolean>;
  unless (region.exits | region.catcher.exit-function)
    error("Block still around with no exits?");
  end;
  #f;
end;

define method doesnt-return? (region :: <block-region>) => res :: <boolean>;
  unless (region.exits)
    error("Block still around with no exits?");
  end;
  #f;
end;

define method doesnt-return? (region :: <exit>) => res :: <boolean>;
  #t;
end;

define method doesnt-return? (region :: <lambda>) => res :: <boolean>;
  region.result-type == empty-ctype();
end;




// FER editing utilities.

// combine-regions -- internal.
//
// Takes two subtrees of FER and combines them into one subtree.  The result
// is interally consistent (i.e. the two input regions will have their
// parent link updated if necessary).  This routine does NOT check the
// first subregion to see if it exits or not (i.e. whether the second subregion
// is actually reachable.
// 
define generic combine-regions
    (first :: <region>, second :: <region>) => res :: <region>;

define method combine-regions
    (first :: <region>, second :: <region>) => res :: <region>;
  let merged = combine-regions-aux(first, second);
  if (merged)
    merged;
  else
    let compound = make(<compound-region>, regions: list(first, second));
    first.parent := second.parent := compound;
    compound;
  end;
end;

define method combine-regions
    (first :: <region>, second :: <compound-region>) => res :: <region>;
  if (instance?(second, <empty-region>))
    first;
  else
    let regions = second.regions;
    let merged = combine-regions-aux(first, regions.head);
    if (merged)
      regions.head := merged;
      merged.parent := second;
    else
      second.regions := pair(first, regions);
      first.parent := second;
    end;
    second;
  end;
end;

define method combine-regions
    (first :: <compound-region>, second :: <region>) => res :: <region>;
  if (instance?(first, <empty-region>))
    second;
  else
    for (scan = first.regions.tail then scan.tail,
	 prev = first.regions then scan,
	 until: scan == #())
    finally
      let merged = combine-regions-aux(prev.head, second);
      if (merged)
	prev.head := merged;
	merged.parent := first;
      else
	prev.tail := list(second);
	second.parent := first;
      end;
    end;
    first;
  end;
end;

define method combine-regions
    (first :: <compound-region>, second :: <compound-region>)
    => res :: <region>;
  if (instance?(first, <empty-region>))
    second;
  elseif (instance?(second, <empty-region>))
    first;
  else
    for (scan = first.regions.tail then scan.tail,
	 prev = first.regions then scan,
	 until: scan == #())
    finally
      let merged = combine-regions-aux(prev.head, second.regions.head);
      if (merged)
	prev.head := merged;
	merged.parent := first;
	prev.tail := second.regions.tail;
      else
	prev.tail := second.regions;
      end;
      for (region in prev.tail)
	region.parent := first;
      end;
    end;
    first;
  end;
end;


define method combine-regions-aux
    (first :: <simple-region>, second :: <simple-region>)
    => res :: false-or(<simple-region>);
  let last-of-first = first.last-assign;
  let first-of-second = second.first-assign;

  last-of-first.next-op := first-of-second;
  first-of-second.prev-op := last-of-first;

  first.last-assign := second.last-assign;

  for (assign = first-of-second then assign.next-op,
       while: assign)
    assign.region := first;
  end;

  first;
end;

define method combine-regions-aux
    (first :: <region>, second :: <region>)
    => res :: false-or(<simple-region>);
  #f;
end;

// split-after - internal
//
// Splits the region containing the assignment into two regions with the
// split following the assignment.  The assignments in the two result
// regions will have correct region links, but the parent link of the two
// results is undefined.
// 
define method split-after (assign :: <abstract-assignment>)
    => (before :: <linear-region>, after :: <linear-region>);
  let next = assign.next-op;
  let region = assign.region;
  if (next)
    let last = region.last-assign;
    assign.next-op := #f;
    region.last-assign := assign;
    let new = make(<simple-region>);
    new.first-assign := next;
    next.prev-op := #f;
    new.last-assign := last;
    for (foo = next then foo.next-op,
	 while: foo)
      foo.region := new;
    end;
    values(region, new);
  else
    values(region, make(<empty-region>));
  end;
end;

// split-before -- internal
//
// Splits the region containing the assignment into two regions with the
// split preceding the assignment.  The assignments in the two result
// regions will have correct region links, but the parent link of the two
// results is undefined.
// 
define method split-before (assign :: <abstract-assignment>)
    => (before :: <linear-region>, after :: <linear-region>);
  let prev = assign.prev-op;
  if (prev)
    split-after(prev);
  else
    values(make(<empty-region>), assign.region);
  end;
end;

// insert-after -- internal
//
// Insert the region immediate after the assignment.  All appropriate parent
// and region links are updated.
//
define generic insert-after
    (component :: <component>, assign :: <abstract-assignment>,
     insert :: <region>) => ();

define method insert-after
    (component :: <component>, assign :: <abstract-assignment>,
     insert :: <region>) => ();
  let region = assign.region;
  let parent = region.parent;
  let (before, after) = split-after(assign);
  let new = combine-regions(combine-regions(before, insert), after);
  new.parent := parent;
  replace-subregion(component, parent, region, new);
end;
    
define method insert-after
    (component :: <component>, assign :: <abstract-assignment>,
     insert :: <empty-region>)
    => ();
end;

// insert-before -- internal
//
// Insert the region immediate before the assignment.  All appropriate parent
// and region links are updated.
//
define generic insert-before
    (component :: <component>, before :: <dependent-mixin>,
     insert :: <region>)
    => ();

define method insert-before
    (component :: <component>, assign :: <abstract-assignment>,
     insert :: <region>)
    => ();
  let region = assign.region;
  let parent = region.parent;
  let (before, after) = split-before(assign);
  let new = combine-regions(combine-regions(before, insert), after);
  new.parent := parent;
  replace-subregion(component, parent, region, new);
end;
    
define method insert-before
    (component :: <component>, assign :: <abstract-assignment>,
     insert :: <empty-region>)
    => ();
end;

define method insert-before
    (component :: <component>, region :: <if-region>, insert :: <region>)
    => ();
  // Note: the region.parent must be evaluated first because combine-regions
  // is allowed to dick with the parent links.
  replace-subregion(component, region.parent, region,
		    combine-regions(insert, region));
end;

define method insert-before
    (component :: <component>, op :: <operation>, insert :: <region>)
    => ();
  insert-before(component, op.dependents.dependent, insert);
end;

define method insert-before
    (component :: <component>, lambda :: <lambda>, insert :: <region>)
    => ();
  // Note: when we are inserting before a lambda, we are really inserting
  // before the *end* of the lambda.
  replace-subregion(component, lambda, lambda.body,
		    combine-regions(lambda.body, insert));
end;

// replace-subregion -- internal
//
// Replace region's child old with new.  This is NOT a deletion.  None of the
// code associated with old is deleted.  It is assumed that this routine will
// be used to edit the tree structure of regions while keeping the underlying
// assignments the same.  The new region's parent slot is updated.
//
define generic replace-subregion
    (component :: <component>, region :: <body-region>, old :: <region>,
     new :: <region>)
    => ();

define method replace-subregion
    (component :: <component>, region :: <body-region>, old :: <region>,
     new :: <region>)
    => ();
  unless (region.body == old)
    error("Replacing unknown region");
  end;
  region.body := new;
  new.parent := region;
end;

define method replace-subregion
    (component :: <component>, region :: <if-region>, old :: <region>,
     new :: <region>)
    => ();
  if (region.then-region == old)
    region.then-region := new;
  elseif (region.else-region == old)
    region.else-region := new;
  else
    error("Replacing unknown region");
  end;
  new.parent := region;
  if (instance?(region.then-region, <empty-region>)
	& instance?(region.else-region, <empty-region>))
    queue-dependent(component, region);
  end;
end;

define method replace-subregion
    (component :: <component>, region :: <compound-region>, old :: <region>,
     new :: <region>)
    => ();
  for (scan = region.regions then scan.tail,
       prev = #f then scan,
       until: scan == #() | scan.head == old)
  finally
    if (scan == #())
      error("Replacing unknown region");
    end;
    let before-split
      = if (prev)
	  prev.tail := #();
	  region;
	else
	  make(<empty-region>);
	end;

    let after-splice = make(<compound-region>, regions: scan.tail);
    for (sub-region in after-splice.regions)
      sub-region.parent := after-splice;
    end;

    let parent = region.parent;
    let combo = combine-regions(before-split,
				combine-regions(new, after-splice));
    unless (combo == region)
      replace-subregion(component, parent, region, combo);
    end;
  end;
end;


// Sanity checking code.

define method assure-all-done (component :: <component>) => ();
  for (lambda in component.all-methods)
    assure-all-done-region(component, lambda);
  end;
end;

define method assure-all-done-region
    (component :: <component>, region :: <simple-region>) => ();
  for (assign = region.first-assign then assign.next-op,
       while: assign)
    assure-all-done-expr(component, assign.depends-on.source-exp);
    assure-all-done-dependent(component, assign);
  end;
end;

define method assure-all-done-region
    (component :: <component>, region :: <compound-region>) => ();
  for (subregion in region.regions)
    assure-all-done-region(component, subregion);
  end;
end;

define method assure-all-done-region
    (component :: <component>, region :: <if-region>) => ();
  assure-all-done-dependent(component, region);
  assure-all-done-region(component, region.then-region);
  assure-all-done-region(component, region.else-region);
end;

define method assure-all-done-region
    (component :: <component>, region :: <body-region>) => ();
  assure-all-done-region(component, region.body);
end;

define method assure-all-done-region
    (component :: <component>, region :: <exit>) => ();
end;

define method assure-all-done-region
    (component :: <component>, lambda :: <lambda>) => ();
  assure-all-done-region(component, lambda.body);
  assure-all-done-dependent(component, lambda);
end;

define method assure-all-done-dependent
    (component :: <component>, dependent :: <dependent-mixin>) => ();
  optimize(component, dependent);
  if (component.initial-definitions | component.reoptimize-queue)
    error("optimizing %= did something, but we thought we were done.",
	  dependent);
  end;
end;

define method assure-all-done-expr
    (component :: <component>, expr :: <expression>) => ();
end;

define method assure-all-done-expr
    (component :: <component>, op :: <operation>) => ();
  assure-all-done-dependent(component, op);
end;



define method check-sanity (component :: <component>) => ();
  //
  // Make sure the component's parent is #f.
  if (component.parent)
    error("Component %= has non-#f parent %=",
	  component, component.parent);
  end;
  //
  // Check the lambdas.
  for (lambda in component.all-methods)
    check-sanity(lambda);
  end;
end;

define method check-sanity (reg :: <simple-region>) => ();
  for (assign = reg.first-assign then assign.next-op,
       prev = #f then assign,
       while: assign)
    //
    // Check that the assigment has the correct region.
    unless (assign.region == reg)
      error("assignment %= claims %= as its region instead of %=",
	    assign, assign.region, reg);
    end;
    //
    // Check that the assignment is linked correctly.
    unless (assign.prev-op == prev)
      error("assignment %= claims %= as its predecessor instead of %=",
	    assign, assign.prev-op, prev);
    end;
    //
    // Check the defines.
    for (defn = assign.defines then defn.definer-next,
	 while: defn)
      unless (defn.definer == assign)
	error("assignment %='s result %= claims its definer is %=",
	      assign, defn, defn.definer);
      end;
    end;
    //
    // Check the dependent aspect of this assignment.
    check-dependent(assign);
  end;
end;

define method check-sanity (region :: <compound-region>) => ();
  for (subregion in region.regions)
    //
    // Check to make sure the subregion's parent is correct.
    unless (subregion.parent == region)
      error("%= claims %= for its parent instead of %=",
	    subregion, subregion.parent, region);
    end;
    //
    // Check the subregion.
    check-sanity(subregion);
  end;
end;

define method check-sanity (region :: <if-region>) => ();
  //
  // Check the dependent aspects.
  check-dependent(region);
  //
  // Check to make sure the subregion's parent links are correct.
  unless (region.then-region.parent == region)
    error("%= claims %= for its parent instead of %=",
	  region.then-region, region.then-region.parent, region);
  end;
  unless (region.else-region.parent == region)
    error("%= claims %= for its parent instead of %=",
	  region.else-region, region.else-region.parent, region);
  end;
  //
  // Check the sub regions.
  check-sanity(region.then-region);
  check-sanity(region.else-region);
end;

define method check-sanity (region :: <body-region>) => ();
  unless (region.body.parent == region)
    error("%='s body %= claims %= for its parent.",
	  region, region.body, region.body.parent);
  end;
  check-sanity(region.body);
end;

define method check-sanity (lambda :: <lambda>) => ();
  //
  // Check the expression aspects of the lambda.
  check-expression(lambda);
  //
  // Check the dependent aspects of the lambda.
  check-dependent(lambda);
  //
  // Check the lambda's body.
  unless (lambda.body.parent == lambda)
    error("%='s body %= claims %= as its parent",
	  lambda, lambda.body, lambda.body.parent);
  end;
  check-sanity(lambda.body);
end;

define method check-sanity (exit :: <exit>) => ();
  //
  // Make sure the exit exits to some block above us.
  for (region = exit then region.parent,
       until: region == #f | region == exit.block-of)
    unless (region)
      error("exit %= exits to block %= but that isn't an ancestor",
	    exit, exit.block-of);
    end;
  end;
end;


define method check-expression (expr :: <expression>) => ();
  //
  // Make sure all the dependents refer to this source.
  for (dep = expr.dependents then dep.source-next,
       while: dep)
    unless (dep.source-exp == expr)
      error("%='s dependent %= claims %= for its source-exp",
	    expr, dep, dep.source-exp);
    end;
    //
    // And make sure that dependent depends on us.
    for (other-dep = dep.dependent.depends-on then other-dep.dependent-next,
	 until: other-dep == dep)
      unless (other-dep)
	error("%= lists %= as a dependent, but it isn't in the "
		"depends-on chain.",
	      expr, dep.dependent);
      end;
    end;
  end;
end;

define method check-expression (op :: <operation>, #next next-method) => ();
  //
  // Check the expression aspects of an operation.
  next-method();
  //
  // Check the dependent aspects of an operation.
  check-dependent(op);
end;

define method check-dependent (dep :: <dependent-mixin>) => ();
  for (dependency = dep.depends-on then dependency.dependent-next,
       while: dependency)
    //
    // Make sure everything we depend on agrees.
    unless (dependency.dependent == dep)
      error("%='s dependency %= claims %= for its dependent",
	    dep, dependency, dep.dependent);
    end;
    //
    // Make make sure that source is okay.
    check-expression(dependency.source-exp);
    //
    // Make sure that source lists us as a dependent.
    for (sources-dependency = dependency.source-exp.dependents
	   then sources-dependency.source-next,
	 until: sources-dependency == dependency)
      unless (sources-dependency)
	error("%= depends on %=, but isn't listed as a dependent.",
	      dep, dependency.source-exp);
      end;
    end;
  end;
end;
