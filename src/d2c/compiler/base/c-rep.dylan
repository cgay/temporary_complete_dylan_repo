module: c-representation
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/c-rep.dylan,v 1.10 1995/05/05 14:41:11 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.

define constant $byte-bits = 8;

define constant $pointer-alignment = 4;
define constant $pointer-size = 4;
define constant $short-alignment = 2;
define constant $short-size = 2;
define constant $int-alignment = 2;
define constant $int-size = 2;
define constant $long-alignment = 4;
define constant $long-size = 4;
define constant $single-alignment = 4;
define constant $single-size = 4;
define constant $double-alignment = 8;
define constant $double-size = 8;
define constant $long-double-alignment = 8;
define constant $long-double-size = 8;

define constant $data-word-size = max($pointer-size, $long-size);

define class <c-representation> (<representation>)
  slot more-general-representation :: union(<false>, <representation>),
    setter: #f, init-value: #f, init-keyword: more-general:;
  slot representation-depth :: <fixed-integer>;
  slot representation-to-more-general :: union(<byte-string>, one-of(#t, #f)),
    init-value: #t, init-keyword: to-more-general:;
  slot representation-from-more-general
    :: union(<byte-string>, one-of(#t, #f)),
    init-value: #t, init-keyword: from-more-general:;
  slot representation-alignment :: <fixed-integer>, setter: #f,
    required-init-keyword: alignment:;
  slot representation-size :: <fixed-integer>, setter: #f,
    required-init-keyword: size:;
  slot representation-c-type :: <string>, setter: #f,
    required-init-keyword: c-type:;
end;

define method representation-has-bottom-value? (res :: <representation>)
    => res :: <boolean>;
  #t;
end;

define method initialize (rep :: <c-representation>, #next next-method,
			  #key more-general)
  next-method();
  rep.representation-depth
    := if (more-general)
	 more-general.representation-depth + 1;
       else
	 0;
       end;
end;

define method print-object (rep :: <c-representation>, stream :: <stream>)
    => ();
  pprint-fields(rep, stream, c-type: rep.representation-c-type);
end;

define class <general-representation> (<c-representation>)
  keyword to-more-general:, init-value: #f;
  keyword from-more-general:, init-value: #f;
end;

define class <immediate-representation> (<c-representation>)
end;

define method representation-has-bottom-value?
    (res :: <immediate-representation>)
    => res :: <boolean>;
  #f;
end;

define class <data-word-representation> (<immediate-representation>)
  slot representation-class :: <cclass>, required-init-keyword: class:;
  slot representation-data-word-member :: <byte-string>,
    required-init-keyword: data-word-member:;
end;

define constant $general-rep
  = make(<general-representation>,
	 alignment: $pointer-alignment, size: $pointer-size + $data-word-size,
	 c-type: "descriptor_t");
define constant $heap-rep
  = make(<c-representation>,
	 alignment: $pointer-alignment, size: $pointer-size,
	 c-type: "heapptr_t", more-general: $general-rep,
	 to-more-general: #f, from-more-general: "%s.heapptr");
define constant $boolean-rep
  = make(<immediate-representation>, more-general: $heap-rep,
	 to-more-general: "(%s ? obj_True : obj_False)",
	 from-more-general: "(%s != obj_False)",
	 alignment: $int-alignment, size: $int-size,
	 c-type: "boolean");

define variable *long-rep* = #f;
define variable *int-rep* = #f;
define variable *uint-rep* = #f;
define variable *short-rep* = #f;
define variable *ushort-rep* = #f;
define variable *byte-rep* = #f;
define variable *ubyte-rep* = #f;

define method seed-representations () => ();
  local
    method set-representations(class, speed-rep, space-rep) => ();
      class.speed-representation := speed-rep;
      class.space-representation := space-rep;
    end;
  begin
    let space-rep = make(<immediate-representation>,
			 more-general: $boolean-rep,
			 alignment: 1, size: 1, c-type: "bool");
    set-representations(dylan-value(#"<boolean>"), $boolean-rep, space-rep);
    set-representations(dylan-value(#"<true>"), $boolean-rep, space-rep);
    set-representations(dylan-value(#"<false>"), $boolean-rep, space-rep);
  end;
  begin
    let fixed-int-cclass = dylan-value(#"<fixed-integer>");
    *long-rep* := make(<data-word-representation>,
		       alignment: $long-alignment, size: $long-size,
		       more-general: $general-rep, c-type: "long",
		       to-more-general: #f,
		       from-more-general: "%s.dataword.l",
		       class: fixed-int-cclass, data-word-member: "l");
    *int-rep* := make(<data-word-representation>,
		      alignment: $int-alignment, size: $int-size,
		      more-general: *long-rep*, c-type: "int",
		      class: fixed-int-cclass, data-word-member: "l");
    *uint-rep* := make(<data-word-representation>,
		       alignment: $int-alignment, size: $int-size,
		       more-general: *long-rep*, c-type: "unsigned int",
		       class: fixed-int-cclass, data-word-member: "l");
    *short-rep* := make(<data-word-representation>,
			alignment: $short-alignment, size: $short-size,
			more-general: *int-rep*, c-type: "short",
			class: fixed-int-cclass, data-word-member: "l");
    *ushort-rep* := make(<data-word-representation>,
			 alignment: $short-alignment, size: $short-size,
			 more-general: *uint-rep*, c-type: "unsigned short",
			 class: fixed-int-cclass, data-word-member: "l");
    *byte-rep* := make(<data-word-representation>, alignment: 1, size: 1,
		       more-general: *short-rep*, c-type: "signed char",
		       class: fixed-int-cclass, data-word-member: "l");
    *ubyte-rep* := make(<data-word-representation>, alignment: 1, size: 1,
			more-general: *ushort-rep*, c-type: "unsigned char",
			class: fixed-int-cclass, data-word-member: "l");
    set-representations(fixed-int-cclass, *long-rep*, *long-rep*);
  end;
  begin
    let sf-cclass = dylan-value(#"<single-float>");
    let sf-rep
      = make(<data-word-representation>, more-general: $general-rep,
	     to-more-general: #f, from-more-general: "%s.dataword.f",
	     alignment: 4, size: 4, c-type: "float",
	     class: sf-cclass, data-word-member: "f");
    set-representations(sf-cclass, sf-rep, sf-rep);
  end;
  begin
    let df-class = dylan-value(#"<double-float>");
    let df-rep
      = if ($double-size > $data-word-size)
	  make(<immediate-representation>, more-general: $heap-rep,
	       to-more-general: "make_double_float(%s)",
	       from-more-general: "double_float_value(%s)",
	       alignment: $double-alignment, size: $double-size,
	       c-type: "double");
	else
	  make(<data-word-representation>, more-general: $general-rep,
	       to-more-general: #f, from-more-general: "%s.dataword.d",
	       alignment: $double-alignment, size: $double-size,
	       c-type: "double", class: df-class, data-word-member: "d");
	end;
    set-representations(df-class, df-rep, df-rep);
  end;
  begin
    let xf-class = dylan-value(#"<extended-float>");
    let xf-rep
      = if ($long-double-size > $data-word-size)
	  make(<immediate-representation>, more-general: $heap-rep,
	       to-more-general: "make_extended_float(%s)",
	       from-more-general: "extended_float_value(%s)",
	       alignment: $long-double-alignment, size: $long-double-size,
	       c-type: "double");
	else
	  make(<data-word-representation>, more-general: $general-rep,
	       to-more-general: #f, from-more-general: "%s.dataword.x",
	       alignment: $long-double-alignment, size: $long-double-size,
	       c-type: "long double", class: xf-class, data-word-member: "x");
	end;
    set-representations(xf-class, xf-rep, xf-rep);
  end;
end;


define method pick-representation
    (type :: <ctype>, optimize-for :: one-of(#"speed", #"space"))
    => rep :: <c-representation>;
  $general-rep;
end;

define method pick-representation
    (type :: <cclass>, optimize-for == #"speed")
    => rep :: <c-representation>;
  speed-representation(type)
    | begin
	assign-representations(type);
	speed-representation(type);
      end;
end;

define method pick-representation
    (type :: <cclass>, optimize-for == #"space")
    => rep :: <c-representation>;
  space-representation(type)
    | begin
	assign-representations(type);
	space-representation(type);
      end;
end;

define variable *assigning-representations-for* = #();

define method potentially-uses-data-word-rep? (class :: <cclass>)
    => res :: <boolean>;
  class.functional?
    & ~member?(class, *assigning-representations-for*)
    & class.sealed?
    & empty?(class.direct-subclasses)
    & class.all-slot-infos.size == 2;
end;


define method assign-representations (class :: <cclass>) => ();
  //
  // First, check to see if the class is abstract.
  if (class.abstract?)
    //
    // Currently, abstract classes can only have abstract superclasses, but
    // check that because we depend on it and it might change.
    assert(every?(abstract?, class.precedence-list));
    //
    // The class is indeed abstract.  So we have to pick between the
    // general rep and the heap rep.  We would rather use the heap rep
    // but we can only do that if we can determine that no subclasses can
    // possibly have a data-word rep.
    let rep
      = if (class.sealed?)
	  //
	  // The class is sealed, so we can check all the subclasses if
	  // necessary.
	  //
	  if (class.all-slot-infos.size > 2)
	    //
	    // If there are more than two slots, no subclass can possibly use
	    // a data word representation.
	    $heap-rep;
	  else
	    block (return)
	      for (subclass in class.subclasses)
		//
		// Don't bother considering abstract classes.
		unless (subclass.abstract?)
		  //
		  // Check the representation of the subclass.  Note: if the
		  // slot type of the subclass is this class we will end
		  // up right back here.  But the subclass will have been
		  // added to *assigning-reps-for* so the next time though
		  // it will return $heap-rep.  Which is what we want to
		  // see.
		  let subclass-rep = pick-representation(subclass, #"speed");
		  if (instance?(subclass-rep, <data-word-representation>)
			| instance?(subclass-rep, <general-representation>))
		    return($general-rep);
		  end;
		end;
	      end;
	      //
	      // We only get here if none of the subclasses wanted a data
	      // word.  So use the heap representation.
	      $heap-rep;
	    end;
	  end;
	else
	  //
	  // The class is open, so new classes could be added at any time.
	  //
	  select (class.all-slot-infos.size)
	    1 =>
	      // Only one slot (%object-class) so any newly added subclass
	      // might very well pick a data-word representation.
	      $general-rep;
	    2 =>
	      // Two slots (%object-class and one other).  If that other slot
	      // can't have a data-word representation, then no subclasses
	      // can have a data-word representation.  Therefore, we can use
	      // the heap representation.
	      //
	      // But we need to protect against recursion.  This can happen
	      // two ways: the slot's type involves us directly, or the slot's
	      // type is another potentially data-word represented class
	      // that involves us in its slot type.  The second case will
	      // be handled by the recursion protection below, but the first
	      // case won't be.  So we have to protect against it here.
	      //
	      // Either way, we guess we won't end up needed the general rep.
	      // This guess might turn out wrong, but if so, we'll fix it up
	      // during the unwind.
	      // 
	      if (member?(class, *assigning-representations-for*))
		$heap-rep;
	      else
		let old-assigning-reps-for = *assigning-representations-for*;
		block ()
		  *assigning-representations-for*
		    := pair(class, old-assigning-reps-for);
		  let type = class.all-slot-infos[1].slot-type;
		  let slot-rep = pick-representation(type, #"speed");
		  if (instance?(slot-rep, <data-word-representation>)
			| instance?(slot-rep, <general-representation>))
		    $general-rep;
		  else
		    $heap-rep;
		  end;
		cleanup
		  *assigning-representations-for* := old-assigning-reps-for;
		end;
	      end;
	    otherwise =>
	      $heap-rep;
	  end;
	end;
    class.speed-representation := rep;
    class.space-representation := rep;

  else
    //
    // The class is concrete.  See if we can use a data-word representation
    // for it.  If not, then use the heap representation.
    if (potentially-uses-data-word-rep?(class))
      let old-assigning-reps-for = *assigning-representations-for*;
      block ()
	*assigning-representations-for* := pair(class, old-assigning-reps-for);
	let type = class.all-slot-infos[1].slot-type;
	let speed-rep = pick-representation(type, #"speed");
	if (instance?(speed-rep, <data-word-representation>))
	  local
	    method dup-rep (rep :: <data-word-representation>)
	      make(<data-word-representation>,
		   more-general: $general-rep,
		   to-more-general: #f,
		   from-more-general: rep.representation-from-more-general,
		   alignment: rep.representation-alignment,
		   size: rep.representation-size,
		   c-type: rep.representation-c-type,
		   class: class,
		   data-word-member: rep.representation-data-word-member);
	    end;
	  class.speed-representation := dup-rep(speed-rep);
	  class.space-representation
	    := dup-rep(pick-representation(type, #"space"));
	else
	  class.speed-representation := $heap-rep;
	  class.space-representation := $heap-rep;    
	end;
      cleanup
	*assigning-representations-for* := old-assigning-reps-for;
      end;
    else
      class.speed-representation := $heap-rep;
      class.space-representation := $heap-rep;    
    end;
  end;
end;

define method pick-representation
    (type :: <limited-ctype>, optimize-for :: one-of(#"speed", #"space"))
    => rep :: <c-representation>;
  pick-representation(type.base-class, optimize-for);
end;


define variable *byte-char-rep* = #f;

define method pick-representation
    (type :: <byte-character-ctype>, optimize-for == #"space")
    => rep :: <c-representation>;
  if (*byte-char-rep*)
    *byte-char-rep*;
  else
    let char-rep = pick-representation(type.base-class, optimize-for);
    *byte-char-rep*
      := make(<data-word-representation>, more-general: char-rep,
	      alignment: 1, size: 1, c-type: "unsigned char",
	      class: type.base-class, data-word-member: "l");
  end;
end;


define method pick-representation
    (type :: <limited-integer-ctype>, optimize-for == #"space",
     #next next-method)
    => rep :: <c-representation>;
  if (type.base-class == dylan-value(#"<fixed-integer>"))
    let bits = max(integer-length(type.low-bound),
		   integer-length(type.high-bound));
    if (negative?(type.low-bound))
      let bytes = ceiling/(bits + 1, $byte-bits);
      if (bytes <= 1)
	*byte-rep*;
      elseif (bytes <= $short-size)
	*short-rep*;
      elseif (bytes <= $int-size)
	*int-rep*;
      else
	*long-rep*;
      end;
    else
      let bytes = ceiling/(bits, $byte-bits);
      if (bytes <= 1)
	*ubyte-rep*;
      elseif (bytes <= $short-size)
	*ushort-rep*;
      elseif (bytes <= $int-size)
	*uint-rep*;
      else
	*long-rep*;
      end;
    end;
  else
    next-method();
  end;
end;

define method integer-length (int :: <integer>) => res :: <integer>;
  if (negative?(int))
    integer-length(lognot(int));
  else
    for (len from 0,
	 int = int then ash(int, -1),
	 until: zero?(int))
    finally
      len;
    end;
  end;
end;

define method pick-representation
    (type :: <union-ctype>, optimize-for :: one-of(#"speed", #"space"))
    => rep :: <c-representation>;
  let mem = type.members;
  if (empty?(mem))
    error("The empty type has no representation.");
  else
    reduce1(merge-representations,
	    map(rcurry(pick-representation, optimize-for), mem));
  end;
end;

define method merge-representations
    (rep1 :: <c-representation>, rep2 :: <c-representation>)
    => res :: <c-representation>;
  if (rep1 == rep2)
    rep1;
  elseif (rep1.representation-depth > rep2.representation-depth)
    merge-representations(rep1.more-general-representation, rep2);
  else
    merge-representations(rep1, rep2.more-general-representation);
  end;
end;
