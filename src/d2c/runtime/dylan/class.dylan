rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/runtime/dylan/class.dylan,v 1.5 1995/11/16 03:35:35 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.
module: dylan-viscera

define class <class> (<type>)
  //
  slot debug-name :: <symbol>, setter: #f,
    required-init-keyword: debug-name:;
  //
  slot unique-id :: <fixed-integer>, init-value: -1,
    setter: #f;
  //
  // The direct superclasses.
  slot direct-superclasses :: <simple-object-vector>, setter: #f,
    required-init-keyword: superclasses:;
  //
  // The Class Precedence List.  We are the first and <object> is the last.
  // Filled in by initialize.
  slot all-superclasses :: <simple-object-vector>,
    required-init-keyword: all-superclasses:;
  //
  // The primary superclass that is closest to us in the hierarchy (including
  // ourself).  Filled in by initialize.
  slot closest-primary-superclass :: <class>,
    required-init-keyword: closest-primary-superclass:;
  //
  // The direct subclasses.
  slot direct-subclasses :: <list>,
    init-value: #();
  //
  // Boolean properties of classes.
  slot class-functional? :: <boolean>, setter: #f,
    init-value: #f, init-keyword: functional:;
  slot class-primary? :: <boolean>, setter: #f,
    init-value: #f, init-keyword: primary:;
  slot class-abstract? :: <boolean>, setter: #f,
    init-value: #f, init-keyword: abstract:;
  slot class-sealed? :: <boolean>, setter: #f,
    init-value: #t, init-keyword: sealed:;
  //
  // The defered evaluations for this class.
  slot class-defered-evaluations :: false-or(<function>),
    init-value: #f;
  //
  // The key defaulter function, or #f if no key defaults.
  slot class-key-defaulter :: false-or(<function>),
    init-value: #f;
  //
  // The maker function, or #f if we haven't computed it yet.
  slot class-maker :: false-or(<function>),
    init-value: #f;
/*
  //
  // Vector of the slots introduced by this class.
  slot class-slots :: <simple-object-vector>, setter: #f,
    required-init-keyword: slots:;
  //
  // Vector of keyword initialization arguments introduced by this class.
  slot class-keyword-init-args :: <simple-object-vector>, setter: #f,
    required-init-keyword: keyword-init-args:;
  //
  // Vector of inherited slot overrides introduced by this class.
  slot class-slot-overrides :: <simple-object-vector>, setter: #f,
    required-init-keyword: slot-overrides:;
  //
  // Vector of all the slots for this class.  Filled in when defered-
  // evaluations are processed.
  slot class-all-slots :: <simple-object-vector>;
  //
  // Layout of instance allocation slots.  #f until computed.
  slot class-instance-layout :: type-union(<false>, <layout>),
    init-value: #f;
  //
  // Layout of each-subclass allocation slots.  #f until computed or if there
  // are no each-subclass slots.
  slot class-each-subclass-layout :: type-union(<false>, <layout>),
    init-value: #f;
  //
  // Vector of each-subclass allocation slots.  Filled in when the layout
  // is computed.
  slot class-each-subclass-slots :: <simple-object-vector>;
*/
  slot subtype-cache :: false-or(<class>), init-value: #f;
end;

/*
define method initialize (class :: <class>, #key)
  class.all-superclasses := compute-cpl(class, class.direct-superclasses);
  class.closest-primary-superclass := find-closest-primary-superclass(class);
end;

define constant <slot-allocation>
  = one-of(#"instance", #"class", #"each-subclass", #"constant", #"virtual");

define class <slot-descriptor> (<object>)
  //
  // How this slot is to be allocated.
  slot slot-allocation :: <slot-allocation>, setter: #f,
    required-init-keyword: allocation:;
  //
  // The type of the slot, or #f it is deferred.
  slot slot-type :: type-union(<false>, <type>),
    required-init-keyword: type:;
  //
  // The function to compute the type when deferred.
  slot slot-deferred-type :: type-union(<false>, <function>),
    required-init-keyword: deferred-type:;
  //
  // The getter generic function.  Also used to identify the slot.
  slot slot-getter :: <generic-function>, setter: #f,
    required-init-keyword: getter:;
  //
  // The method added to that generic function, or #f if it either hasn't
  // beed added yet or isn't going to be added ('cause of virtual allocation).
  slot slot-getter-method :: type-union(<false>, <method>),
    init-value: #f;
  //
  // the setter generic function, or #f if there isn't one.
  slot slot-setter :: type-union(<false>, <generic-function>), setter: #f,
    init-value: #f;
  //
  // The method added to the setter generic function if one had been added.
  slot slot-setter-method :: type-union(<false>, <method>),
    init-value: #f;
  //
  // The function to compute the initial value, or #f if it starts out life
  // unbound.  Note: the init-value: keyword is converted into a function
  // so we don't have to tell them apart.
  slot slot-init-function :: type-union(<false>, <function>),
    init-value: #f;
  //
  // The init keyword, if there is one.
  slot slot-init-keyword :: type-union(<false>, <symbol>),
    init-value: #f;
  //
  // #t if the init-keyword is required, #f if not.
  slot slot-init-keyword-required? :: <boolean>,
    init-value: #f;
end;

define method initialize
    (slot :: <slot-descriptor>,
     #key setter :: type-union(<false>, <generic-function>),
     type :: type-union(<false>, <type>),
     deferred-type :: type-union(<false>, <function>),
     init-value = $not-supplied,
     init-function :: type-union(<false>, <function>),
     init-keyword :: type-union(<false>, <symbol>),
     required-init-keyword :: type-union(<false>, <symbol>),
     allocation :: <slot-allocation> = #"instance")
    => res :: <slot-descriptor>;

  // Check the consistency of the various init options.
  if (required-init-keyword)
    if (init-value ~= $not-supplied)
      error("Can't mix init-value: and required-init-keyword:");
    elseif (init-function)
      error("Can't mix init-function: and required-init-keyword:");
    elseif (init-keyword)
      error("Can't mix init-keyword: and required-init-keyword:");
    end;
  elseif (init-value ~= $not-supplied)
    if (init-function)
      error("Can't mix init-value: and init-function:");
    end;
  end;

  // Check the consistency of the various type options.
  if (deferred-type & type)
    error("Can't mix type: and deferred-type:");
  end;

  
end;

define method make (class == <class>,
		    #key superclasses :: type-union(<class>, <sequence>)
		           = <object>,
		         slots :: <sequence> = #())
  let slots = map-as(<simple-object-vector>,
		     curry(apply, make, <slot-descriptor>),
		     slots);
  next-method(superclasses:
		select (superclasses by instance?)
		  <class> =>
		    vector(superclasses);
		  <sequence> =>
		    as(<simple-object-vector>, superclasses);
		end,
	      slots: slots);
end;

define method initialize (class :: <class>, #key)
  ???;
end;
			      
*/


// Class precedence list computation.

/*

define class <cpd> (<object>)
  slot cpd-class :: <class>, required-init-keyword: class:;
  slot cpd-supers :: <list>, init-value: #();
  slot cpd-after :: <list>, init-value: #();
  slot cpd-count :: <fixed-integer>, init-value: 0;
end;

define method compute-cpl (class :: <class>, supers :: <list>)
    => res :: <list>;
  if (supers == #())
    list(class);
  elseif (supers.tail == #())
    pair(class, supers.head.all-superclasses);
  else
    slow-compute-cpl(class, supers);
  end;
end;

define method slow-compute-cpl (class :: <class>, supers :: <list>)
    => res :: <list>;
  let cpds = make(<table>);
  let class-count = 0;
  local
    method compute-cpd (class :: <class>, supers :: <list>)
      let cpd = make(<cpd>, class: class);
      cpds[class] := cpd;
      class-count := class-count + 1;
      if (supers != #())
	let prev-super-cpd = find-cpd(supers.head);
	cpd.cpd-supers := pair(prev-super-cpd, cpd.cpd-supers);
	cpd.cpd-after := pair(prev-super-cpd, cpd.cpd-after);
	prev-super-cpd.cpd-count := prev-super-cpd.cpd-count + 1;
	for (super :: <class> in supers.tail)
	  let super-cpd = find-cpd(super);
	  cpd.cpd-supers := pair(super-cpd, cpd.cpd-supers);
	  cpd.cpd-after := pair(super-cpd, cpd.cpd-after);
	  prev-super-cpd.cpd-after := pair(super-cpd,prev-super-cpd.cpd-after);
	  super-cpd.cpd-count := super-cpd.cpd-count + 2;
	  prev-super-cpd := super-cpd;
	end;
      end;
      cpd;
    end,
    method find-cpd (class :: <class>)
      element(cpds, class, default: #f)
	| compute-cpd(class, class.direct-superclasses);
    end;
  let candidates = list(compute-cpd(class, supers));
  let rcpl = #();
  for (count :: <fixed-integer> from 0 below class-count)
    let candidate
      = if (candidates == #())
	  error("Inconsistent CPL");
	elseif (candidates.tail == #())
	  candidates.head;
	else
	  tie-breaker(candidates, rcpl);
	end;
    candidates := remove!(candidates, candidate);
    rcpl := pair(candidate.cpd-class, rcpl);
    for (after in candidate.cpd-after)
      if (zero?(after.cpd-count := after.cpd-count - 1))
	candidates := pair(after, candidates);
      end;
    end;
  end;
  reverse!(rcpl);
end;

define method tie-breaker (candidates :: <list>, rcpl :: <list>)
    => candidate :: <cpd>;
  block (return)
    for (class in rcpl)
      let supers = class.direct-superclasses;
      for (candidate in candidates)
	if (member?(candidate.cpd-class, supers))
	  return(candidate);
	end;
      end;
    end;
    lose("Can't happen.\n");
  end;
end;

*/


// Find-closest-primary-superclass

/*

define method find-closest-primary-superclass (class :: <class>)
    => res :: <class>;
  let closest-primary = #f;
  for (super in class.direct-superclasses)
    let other-primary = super.closest-primary-superclass;
    if (~closest-primary | subtype?(other-primary, closest-primary))
      closest-primary := other-primary;
    elseif (~subtype?(closest-primary, other-primary))
      error("Can't mix ~= and ~= because they are both primary",
	    closest-primary, other-primary);
    end;
  end;
  if (class.class-primary?)
    class;
  elseif (closest-primary)
    closest-primary;
  else
    lose("<object> isn't being inherited or isn't primary?");
  end;
end;

*/


// Type system methods.

define method %instance? (object, class :: <class>)
    => res :: <boolean>;
  subtype?(object.object-class, class);
end;

define method subtype? (class1 :: <class>, class2 :: <class>)
    => res :: <boolean>;
  case
    class1 == class2.subtype-cache =>
      #t;
    member?(class2, class1.all-superclasses) =>
      class2.subtype-cache := class1;
      #t;
    otherwise =>
      #f;
  end case;
end;


// Layout stuff.

/*

define method compute-layout (class :: <class>) => ();
  let direct-supers = class.direct-superclasses;
  //
  // First of all, clone the layout info for the first direct superclass.
  // 
  // Note: we can assume that there will be at least one superclass because
  // everything must inherit at least <object>, and <object> itself is set
  // up by the linker.
  let first-super :: <class> = first(direct-supers);
  let processed :: <list> = first-super.all-superclasses;
  let instance-layout = clone-layout(first-super.class-instance-layout);
  let each-subclass-layout
    = (first-super.class-each-subclass-layout
	 & clone-layout(first-super.class-each-subclass-layout));
  let all-slots = 
  //
  // Now, add all the slots for classes picked up from the additional
  // superclasses.
  local method process-super (super)
	  unless (member?(super, processed))
	    processed := pair(super, processed);
	    
	    do(process-super, super.direct-superclasses);
	  end;
	end;
  for (index from 1 below direct-supers.size)
    process-super(direct-supers[index]);
  end;

*/



// The default make method.

define open generic make (class :: <class>, #rest supplied-keys, #all-keys)
    => instance;

define method make (class :: <class>, #rest supplied-keys, #all-keys)
    => instance;
  if (class.class-abstract?)
    error("Can't make instances of %= because it is abstract.", class);
  end;
  if (class.class-defered-evaluations)
    class.class-defered-evaluations();
  end;
  let defaulted-keys :: <simple-object-vector>
    = if (class.class-key-defaulter)
	class.class-key-defaulter(supplied-keys);
      else
	supplied-keys;
      end;
  /*
  let valid-keys = class.class-valid-init-keywords;
  for (index from 0 below defaulted-keys.size by 2)
    let key = defaulted-keys[index];
    unless (member?(key, valid-keys))
      error("Invalid initialization keyword %= in make of %=", key, class);
    end;
  end;
  */
  let instance = apply(class.class-maker, defaulted-keys);
  apply(initialize, instance, defaulted-keys);
  instance;
end;

define open generic initialize (instance :: <object>, #rest keys, #all-keys);

define inline method initialize (instance :: <object>, #all-keys) => ();
end;



// Subclass types.

/* ### not absolutly needed

// <subclass> -- internal
//
// A <subclass> represents all of the subclasses of a particular class,
// conceptually the same as:
//   apply(type-union, map(singleton,all-subclasses(class)))
// assuming a definition for all-subclasses.
//
// Exposed because the constructor is exported.
// 
define class <subclass> (<type>)
  //
  // The class this is the subclasses of.
  slot subclass-of :: <class>, required-init-keyword: of:;
end;

seal generic make (singleton(<subclass>));

// limited(<class>,...) -- exported generic function method.
//
// If they want all the subclasses of <object> then return <class>.  If they
// want all the subclasses on some sealed class, then find them all.
// Otherwise, make a <subclass> type.
//
define method limited (class == <class>, #key subclass-of)
    => res :: <type>;
  if (subclass-of == <object>)
    <class>;
  elseif (class.class-sealed?)
    apply(type-union, singleton(class),
	  map(curry(limited, <class>, subclass-of:),
	      class.direct-subclasses));
  else
    make(<subclass>, of: subclass-of);
  end;
end;

// instance?(<object>,<subclass>) -- exported generic function method.
//
// Nothing but classes (handled below) are instances of subclass types.
//
define method %instance? (object, type :: <subclass>)
    => res :: <boolean>;
  #f;
end;

// instance?(<class>,<subclass>) -- exported generic function method.
//
// A class is a instance of a subclass type iff that class is a subtype of
// of the subclass type's base class.
//
define method %instance? (object :: <class>, type :: <subclass>)
    => res :: <boolean>;
  subtype?(object, type.subclass-of);
end;

// subtype? -- exported generic function method
//
// Unless some more specific method is applicable, a subclass type is a subtype
// of some other type iff the base class's metaclass is a subtype of that
// other type.  We assume that <class> is the only kind of class in existance,
// though.
//
define method subtype? (type1 :: <subclass>, type2 :: <type>)
    => res :: <boolean>;
  subtype?(<class>, type2);
end;

// subtype?(<subclass>,<subclass>) -- exported generic function method.
//
// One subclass type is a subtype of another subclass type if the first
// one's root class is a subclass of the second one's root class.
//
define method subtype? (type1 :: <subclass>, type2 :: <subclass>)
    => res :: <boolean>;
  subtype?(type1.subclass-of, type2.subclass-of);
end;

*/
