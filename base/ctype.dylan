Module: ctype
Description: compile-time type system
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/ctype.dylan,v 1.5 1995/02/23 17:08:28 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

/*
Todo: 
  subclass types (unknown or union of singletons if sealed)
  difference
  limited-collection creation
  class creation database hookup
  primary class intersection
  type specifier list concept? (a parsed but uncanonicalized type)

*/

///    Return the type that describes all objects that are in Type1 but not in
/// Type2.  If we can't determine this type, then return #f
///
define generic ctype-difference(type1 :: <ctype>, type2 :: <ctype>)
       => result :: union(<ctype>, <false>);


/// Superclass of multi-value types and regular single types.
define class <values-ctype> (<object>)
end class;


//// Type function memoization:
///
/// Our primary approach for getting good performance on the type operations is
/// to use memoization, rather than trying to come up with clever ways to
/// quickly determine type relationships.  This based on the observation that
/// relatively few types are actually in use at any given type, and that the
/// compiler does the same operations over and over.

/// Memoization is based on the type-hash, which is a slot shared by all
/// compile-time types.
///
/// <ctype> objects are also hash-consed, which (modulo unknown types)
/// means that == is type equivalence.


/// make a pseudo-random type-hash value.

define variable random-state = 
  make(<integer-uniform-distribution>, from: 0, to: ash(1, 28));

define constant make-type-hash = method ()
  random(random-state);
end;


define abstract class <ctype> (<values-ctype>)
  slot type-hash :: <fixed-integer>, setter: #f, 
       init-keyword: type-hash:, init-function: make-type-hash;
end class;


/// Memoization is done in a vector.  Each entry has four elements: the two arg
/// types, the result type and the result precise flag.  All elements are
/// initialized to #F, which ensures that empty entries will miss (since the
/// arguments are always types.)  This memoization is a probablistic cache, not
/// a complete record of all results ever computed.
///
/// ### vector could be limited to union(<ctype>, one-of(#t, #f));
///
define constant <memo-table> = <simple-object-vector>;

/// log2 of the the number of entries in the table.
define constant memo2-bits = 9;

// mask which gives a vector index from a large hash value.  Low zeros align to
// start of an entry.
define constant memo2-mask = ash(lognot(ash(-1, memo2-bits)), 2);

define constant make-memo2-table = method ()
  make(<memo-table>, size: ash(4, memo2-bits), fill: #f);
end method;

// some hit rate info, for tuning.
define variable memo2-hits = 0;
define variable memo2-probes = 0;

// See if Type1 & Type2 are memoized in Table.  If so, the two memoized values
// are returned.  If not, we return #"miss" and #f;
define constant memo2-lookup = method
   (type1 :: <ctype>, type2 :: <ctype>, table :: <memo-table>)
    => (value :: union(<ctype>, one-of(#f, #t, #"miss")),
        precise :: <boolean>);

  memo2-probes := memo2-probes + 1;
  let base = logand(logxor(type1.type-hash, ash(type2.type-hash, -3)),
                    memo2-mask);
  if (table[base] == type1 & table[base + 1] == type2)
    memo2-hits := memo2-hits + 1;
    values(table[base + 2], table[base + 3]);
  else
    values(#"miss", #f);
  end;
end method;

define constant memo2-enter = method
   (type1 :: <ctype>, type2 :: <ctype>, result :: union(<ctype>, <boolean>),
    precise :: <boolean>, table :: <memo-table>)

  let base = logand(logxor(type1.type-hash, ash(type2.type-hash, -3)),
                    memo2-mask);
  table[base] := type1;
  table[base + 1] := type2;
  table[base + 2] := result;
  table[base + 3] := precise;
end method;
 

//// Equality:
///
///  Since ctypes are hash-consed, equality/inequality is pretty degenerate.
/// The only problem area is with unknown types (whice we could not or elected
/// not to evaluate at compile time.)  Unknown types may be spuriously ~==,
/// so to ensure a precise result we must test for unknown types.  

///    If two types are definitely equivalent, return true.  The second value
/// indicates whether the first value is definitely correct.  This should only
/// fail in the presence of Unknown types.
///
define constant ctype-eq? = method (type1 :: <ctype>, type2 :: <ctype>)
       => (result :: <boolean>, precise :: <boolean>);
  
  if (type1 == type2)
    values(#t, #t);
  else
    values(#f, ~(instance?(type1, <unknown-ctype>) 
                 | instance?(type2, <unknown-ctype>)))
  end;
end method;

/// Similar to ctype-eq, but we return true if the types are definitely not the
/// same.
///
define constant ctype-neq? = method (type1 :: <ctype>, type2 :: <ctype>)
       => (result :: <boolean>, precise :: <boolean>);
  
  if (type1 == type2)
    values(#f, #t);
  elseif (instance?(type1, <unknown-ctype>) | instance?(type2, <unknown-ctype>))
    values(#f, #f);
  else
    values(#t, #t);
  end;
end method;


/// find-direct-classes  --  exported
///
///    Given an arbitrary type, return a list of all the classes that a value
/// of that type could possibly be direct instances of.  If we can't determine
/// this (because an open class is involved) then return #f.  We could
/// potentially return #() if there is no possibly non-abstract class.
///
define generic find-direct-classes(type :: <ctype>) => res :: false-or(<list>);


//// CSUBTYPE?
///

/*

This table summarizes the function implemented by csubtype-dispatch.  Rows are
the class of the first arg, and columns are the class of the second arg.  For
example, a limited integer type is a subtype of a direct instance type only if
the limited base class is the same as the direct instance class.
Non-symmetrically, a direct instance type is never a subtype of a limited
integer type.

  		single     l-int      l-coll      class      direct
---------------------------------------------------------------------------
   singleton:   #f         #f       csubtype?/object-cclass  ==/object-cclass
     lim int:   #f	   subrange   #f	  base-is-   ==base
    lim coll:	#f	   #f         #f	   subclass  #f
       class:   #f	   #f	      #f	  subclass   #f
      direct:	#f         #f	      #f	  subclass   #f

Note that many of these results only hold because of canonicalization which
maps surface forms to other types, e.g. singleton(3) becomes
    limited(<integer>, from: 3, to: 3)

singleton/singleton is false because the types are known to be unequal at this
point.  Similar for direct/direct and l-coll/l-coll.

These rules are not arbitrarily general; they are the simplest ones that work
in our particular type system.  Adding new meta-types could trash everything.

*/


/// Handle csubtype? for unequal types other than union and unknown.
/// Result is always precise because any vagueness is in the unknown types.
///
define sealed generic csubtype-dispatch(type1 :: <ctype>, type2 :: <ctype>)
       => result :: <boolean>;

/// Many cases are false, so make that the default.
define method csubtype-dispatch(type1, type2) => result :: <boolean>;
  #f;
end method;

define variable csubtype-memo = make-memo2-table();

/// Like subtype?, but works on ctypes, and returns the second value #F if the
/// relation cannot be determined at compile time (due to unknown types.)
///
/// Check if result is memoized; if not, pick off the unknown & union cases
/// before calling the generic function.
/// 
define constant csubtype? = method (type1 :: <ctype>, type2 :: <ctype>)
       => (result :: <boolean>, precise :: <boolean>);

  let (memo-val, memo-win) = memo2-lookup(type1, type2, csubtype-memo);
  if (memo-val == #"miss")
    let (val, win) = 
      case
	// Makes unknown types be subtypes of themselves, & eliminates the case
	// of equal types from later consideration.  Also speeds up a common
	// case...
	type1 == type2 => values(#t, #t);

        // the only thing an unknown type is surely a subtype of is <object>
        instance?(type1, <unknown-ctype>) =>
	  if (type2 == object-ctype()) values(#t, #t) else values(#f, #f) end;

	// nothing is a definite subtype of an unknown type (except itself.)
	instance?(type2, <unknown-ctype>) => values(#f, #f);

	// Every member of type1 must be a subtype of some member of type2.
	otherwise =>
	  values(every?(method (t1)
	  		  any?(method (t2) csubtype-dispatch(t1, t2) end,
			       type2.members)
		        end method,
		        type1.members),
		#t);
      end case;

    memo2-enter(type1, type2, val, win, csubtype-memo);
    values(val, win);
  else
    values(memo-val, memo-win);
  end;
end method;


//// Union types:

define class <union-ctype> (<ctype>, <ct-value>)
  // list of ctypes in the union, which can only be classes, limited types or
  // singletons.  Any nested unions are flattened into this one, and the union
  // of anything and an unknown type is itself an unknown type.
  slot members :: <list>, setter: #f, required-init-keyword: members:;
end class;

define method print-object (union :: <union-ctype>, stream :: <stream>) => ();
  pprint-fields(union, stream, members: union.members);
end;

// The "members" of any non-union type is a list of the type itself.
define method members(type :: <ctype>) => result :: <list>;
  list(type);
end method;


// Most type ops have a non-generic wrapper that handles unions and unknowns.
// Not so for find-direct-classes.
define method find-direct-classes(type :: <union-ctype>)
    => res :: false-or(<list>);
  let res = #();
  block (done)
    for (mem in type.members)
      let mem-classes = find-direct-classes(mem);
      if (mem-classes)
	res := concatenate(mem-classes, res);
      else
        done(#f);
      end;
      finally remove-duplicates(res);
    end;
  end;
end method;


// Eliminate subtypes and adjacent integer types.  Result sorted by hash
// code for canonical order.  Does not flatten unions or unknown types.
//
define constant canonicalize-union = method (types :: <list>) => res :: <list>;
  let other = #();
  let ints = #();
  for (elt in types)
    if (instance?(elt, <limited-integer-ctype>))
      ints := limited-int-union(elt, ints);
    else
      other := pair(elt, other);
    end;
  end for;

  let res = #();
  let filtered = concatenate(other, ints);
  for (elt in filtered)
    // omit from result if already in result or a proper subtype of some other
    // element.
    unless (member?(elt, res)
            | any?(method (x) csubtype?(elt, x) & ~(x == elt) end,
		   filtered))
      res := pair(elt, res);
    end;
  end for;
    
  sort!(res,
        test: method (x, y)
        	x.type-hash < y.type-hash
	      end);
end method;


// table used for hash-consing union types.  Key is a list of <ctype>s.
define class <union-table> (<table>)
end class;

define method table-protocol(table :: <union-table>);
  values(\=,
  	 method(key :: <list>)
	   for(elt :: <ctype> in key,
	       res :: <fixed-integer> = 0 then logxor(res, elt.type-hash))
	   finally values(res, $permanent-hash-state);
	   end for;
	 end method);
end;

define variable union-table = make(<union-table>);
define variable union-memo = make-memo2-table();


///    Find a type which includes both types.  The result is an unknown type if
/// either of the arguments are unknown; otherwise the result is precise.  This
/// result is simplified into the canonical form, thus is not a union type
/// unless there is no other way to represent the result.
///
/// If no members, the result is the empty type.  If one, it is that type.
/// Otherwise, check if a union with those members already exists before making
/// a new union type.
///
define constant ctype-union = method (type1 :: <ctype>, type2 :: <ctype>)
    => value :: <ctype>;

  let (value, precise) = memo2-lookup(type1, type2, union-memo);
  case 
    ~(value == #"miss") => value;

    instance?(type1, <unknown-ctype>) =>
      make(<unknown-ctype>, type-exp: type1.type-exp);
   
    instance?(type2, <unknown-ctype>) =>
      make(<unknown-ctype>, type-exp: type2.type-exp);

    otherwise =>
      local frob(canonical)
	if (canonical == #())
	  empty-ctype()
	elseif (tail(canonical) == #())
	  head(canonical)
	else
	  let found = element(union-table, canonical, default: #f);
	  if (found)
	    found
	  else
	    union-table[canonical] := make(<union-ctype>, members: canonical);
	  end;
	end;
      end method;

      let res = frob(
                 canonicalize-union(
 		  concatenate(type1.members, type2.members)));
      memo2-enter(type1, type2, res, #t, union-memo);
      res;
  end;
end method;


//// Intersection:

/*

This table describes the result of ctype-intersection-dispatch.  See the
csubtype? table for qualifications & notes.  Since
intersection is commutative, this matrix is conceptually symmetrical, however
to reduce the number of methods needed, we have a default method which returns
(#f, #f), in which case we try swapping the args.  If that fails, the
intersection is empty.

  		single     l-int      l-coll      class      direct
---------------------------------------------------------------------------
   singleton: 	empty      empty    csubtype?/object-cclass  ==/object-cclass
     lim int:             overlap    empty	  base-is-   ==base
    lim coll:	                     empty	   subclass  empty
       class:                               subclass|sealed  subclass
      direct:	                                             empty

*/


/// Handle ctype-intersection for unequal types other than union and unknown.
/// Result may be imprecise if we intersect two non-sealed classes.
///
define sealed generic ctype-intersection-dispatch
    (type1 :: <ctype>, type2 :: <ctype>)
     => (result :: union(<ctype>, <false>), precise :: <boolean>);

/// Indicates try swapping args, or if that failed, the result is empty.
define method ctype-intersection-dispatch(type1, type2)
     => (result :: union(<ctype>, <false>), precise :: <boolean>);
  values(#f, #t);
end method;


define variable intersection-memo = make-memo2-table();

///    Return as restrictive a type as we can discover that is no more
/// restrictive than the intersection of Type1 and Type2.  The second value is
/// true if the result is exact.  At worst, we arbitrarily return one of the
/// arguments as the first value (trying not to return an unknown type).
///
define constant ctype-intersection = method (type1 :: <ctype>, type2 :: <ctype>)
       => (result :: <ctype>, precise :: <boolean>);

  let (memo-val, memo-win) = memo2-lookup(type1, type2, intersection-memo);
  if (memo-val == #"miss")
    let (val, win) = 
      case
        // Makes unknown types intersect with themselves, & eliminates the case
	// of equal types from later consideration.
	type1 == type2 => values(type1, #t);

        // If one arg is unknown, return the other and #f.
        instance?(type1, <unknown-ctype>) => values(type2, #f);
	instance?(type2, <unknown-ctype>) => values(type1, #f);

	// Otherwise, the intersection is the union of the pairwise
	// intersection of the members.  As described above, we try both
	// orders. 
	otherwise =>
	  let win-int = #t;
	  let res-union = empty-ctype();
	  for (mem1 in type1.members)
	    for (mem2 in type2.members)
	      let (res12, win12) = ctype-intersection-dispatch(mem1, mem2);
	      if (res12)
 	        unless (win12) win-int := #f end;
	        res-union := ctype-union(res-union, res12);
	      else
	        let (res21, win21) = ctype-intersection-dispatch(mem2, mem1);
		if (res21)
		  unless (win21) win-int := #f end;
		  res-union := ctype-union(res-union, res21);

		// else precisely empty, nothing to union.
		end if;
	      end if;
	    end for;
	  end for;
	  values(res-union, win-int);
      end case;

    memo2-enter(type1, type2, val, win, intersection-memo);
    values(val, win);
  else
    values(memo-val, memo-win);
  end;
end method;


/// The first value is true unless the types definitely don't intersect.  The
/// second value is true if the first value is definitely correct.  empty-ctype
/// is considered to intersect with any type.  If either type is <object>, we
/// also return #T, #T.  This way we consider unknown types to intersect with
/// <object>.
///
define constant ctypes-intersect? = method (type1 :: <ctype>, type2 :: <ctype>)
       => (result :: <boolean>, precise :: <boolean>);
  if (type1 == empty-ctype() | type2 == empty-ctype())
    values(#t, #t);
  else
    let (res, win) = ctype-intersection(type1, type2);
    if (win)
      values(~(res == empty-ctype()), #t);
    elseif (type1 == object-ctype() | type2 == object-ctype())
      values(#t, #t);
    else
      values(#t, #f);
    end;
  end;
end method;


/// <unknown-ctype> represents some random non-compile-time expression that
/// ought to be a type.
///
/// This should be interpreted as "some type whose meaning is unknown because
/// the value of EXP is unknown".  An unknown type is never CTYPE-EQ to itself
/// or to any other type.
///
define class <unknown-ctype> (<ctype>)

  // The expression which was of unknown type.  In general, this is only for
  // human context. 
  slot type-exp;
end class;

define method find-direct-classes(type :: <unknown-ctype>) => res :: <false>;
  ignore(type);
  #f;
end;


//// Limited types:
///
/// The <limited-ctype> abstract class is inherited by various non-class types
/// where there is a class that is a "tight" supertype of the type.  This
/// includes singleton and direct-instance types.

define abstract class <limited-ctype> (<ctype>)
  // The most specific class that is a supertype of this type.
  slot base-class :: <cclass>, required-init-keyword: base-class:;
end class;

/// A limited type is only a subtype of a class if the limited class is a
/// subclass of that class. 
define method csubtype-dispatch(type1 :: <limited-ctype>, type2 :: <cclass>)
    => result :: <boolean>;
  subclass?(type1.base-class, type2);
end method;

define method find-direct-classes(type :: <limited-ctype>)
    => res :: false-or(<list>);
  find-direct-classes(type.base-class);
end;


/// Limited integer types:

define class <limited-integer-ctype> (<limited-ctype>, <ct-value>)
  slot low-bound :: union(<integer>, <false>), 
       required-init-keyword: low-bound:;

  slot high-bound :: union(<integer>, <false>), 
       required-init-keyword:  high-bound:;
end class;

define method print-object (limint :: <limited-integer-ctype>,
			    stream :: <stream>)
    => ();
  pprint-fields(limint, stream,
		base-class: limint.base-class,
		if (limint.low-bound) low-bound: end, limint.low-bound,
		if (limint.high-bound) high-bound: end, limint.high-bound);
end;

/// A limited integer type is a subtype of another if the bounds of type1 are
/// not wider that type2's (and the base class is a subtype.)
define method csubtype-dispatch
    (type1 :: <limited-integer-ctype>, type2 :: <limited-integer-ctype>)
    => result :: <boolean>;
  let L1 = type1.low-bound;  
  let L2 = type2.low-bound;  
  let H1 = type1.high-bound;  
  let H2 = type2.high-bound;

  (L1 == L2 | L2 == #f | (L1 ~= #f & L1 >= L2)) 
    & 
  (H1 == H2 | H2 == #f | (H1 ~= #f & H1 <= H2))
    &
  subclass?(type1.base-class, type2.base-class);
end method;


/// The intersection of two limited integer types is the overlap of the ranges.
/// We determine this by maximizing the lower bounds and minimizing the upper
/// bounds, returning that range if non-empty.
define method ctype-intersection-dispatch
    (type1 :: <limited-integer-ctype>, type2 :: <limited-integer-ctype>)
    => (result :: <ctype>, precise :: <true>);

  local innerize(b1, b2, fun)
    case
      ~b1 => b2;
      ~b2 => b1;
      otherwise => fun(b1, b2);
    end;
  end method;

  let rbase = ctype-intersection(type1.base-class, type2.base-class);
  if (rbase)
    let L1 = type1.low-bound;
    let L2 = type2.low-bound;
    let H1 = type1.high-bound;
    let H2 = type2.high-bound;
    let nlow = innerize(L1, L2, max);
    let nhigh = innerize(H1, H2, min);
    if (~nlow | ~nhigh | nlow <= nhigh)
      values(make(<limited-integer-ctype>, base-class: rbase,
                  low-bound: nlow, high-bound: nhigh),
	     #t)
    else
      values(empty-ctype(), #t);
    end if;
  else
    values(empty-ctype(), #t);
  end;
end method;


/// Return a new list of limited integer types with Int joined to any of the
/// types in Others that it intesects.  We don't bother removing the overlapped
/// type, since it will be removed by the subtype elimination pass later on.
///
define constant limited-int-union = method 
    (int :: <limited-integer-ctype>, others :: <list>) => res :: <list>;

  // Return true if the two types have overlapping or contiguous ranges.  Value
  // is arbitrary if one is a subtype of the other, which doesn't matter here.
  local adjacent?(type1, type2)
    let L1 = type1.low-bound;
    let H1 = type1.high-bound;
    let L2 = type2.low-bound;
    let H2 = type2.high-bound;

    if (L1 = #f | (L2 ~= #f & L1 <= L2))
      H1 = #f | L2 = #f | L2 <= H1 + 1;
    else
      L1 = #f | H2 = #f | L1 <= H2 + 1;
    end;
  end method;

  let LI = int.low-bound;
  let HI = int.high-bound;
  let base = int.base-class;
  
  for (other in others)
    let LO = other.low-bound;
    let HO = other.high-bound;

    if (base == other.base-class & adjacent?(int, other))
      if (LI ~= #f & (LO = #f | LO < LI))
        LI := LO;
      end;

      if (HI ~= #f & (HO = #f | HO > HI))
        HI := HO;
      end;
    end;
  end for;

  add-new!(others, make(<limited-integer-ctype>, base-class: base,
	    	        low-bound: LI, high-bound: HI));
end method;


// Table used to hash-cons limited integer types.  Key is a vector of the
// base-class, low and high bounds.
define variable limited-int-table = make(<equal-table>);

// Return a <limited-integer-ctype> corresponding to the args, making a new one
// if necessary.
define method make(wot == <limited-integer-ctype>,
		   #next next-method,
		   #key base-class, low-bound, high-bound)
    => res :: <limited-integer-ctype>;

  let key = vector(base-class, low-bound, high-bound);
  let found = element(limited-int-table, key, default: #f);
  if (found)
    found;
  else
    limited-int-table[key] := next-method();
  end;
end method;


//// Limited collection types:

/// a limited collection can only be a subtype of another if it is identical,
/// and that case is implicitly handled by csubtype?
///
define class <limited-collection-ctype> (<limited-ctype>, <ct-value>)
  slot element-limit :: union(<ctype>, <false>), 
       required-init-keyword: element-limit:;

  slot size-limit :: union(<simple-object-vector>, <false>),
       required-init-keyword: size-limit:;
end class;


//// Direct instance types:

define class <direct-instance-ctype> (<limited-ctype>)
end class;

define method csubtype-dispatch
    (type1 :: <limited-ctype>, type2 :: <direct-instance-ctype>)
    => result :: <boolean>;

  type1.base-class == type2.base-class;
end method;


define method ctype-intersection-dispatch
    (type1 :: <limited-ctype>, type2 :: <direct-instance-ctype>)
    => (result :: union(<ctype>, <false>), precise :: <true>);

  values(if (type1.base-class == type2.base-class) type1 else empty-ctype() end,
         #t);
end method;


//// Singleton types:
///
/// We only represents singletons with compile-time constant (non-integer)
/// values.  Integer values are represented by limited integer types.  Note
/// that in Dylan the only compile-time constants are literals, so we are that
/// we are really restricted to float, character, symbol and magic tokens (#t,
/// #f, #()).  We omit the collection literals (string and list) with no real
/// loss, since they aren't meaningfully compared with ==.

/// ### we may also want to hack singletons of classes, e.g. for specializers.
/// singleton-of-class may want to be a seperate type, or maybe we have a magic
/// compile-time cookie representing the class, or something.

define class <singleton-ctype> (<limited-ctype>, <ct-value>)
  // The base-class is the direct class of this object, which can be used
  // interchangably with the object when testing this object for class
  // membership.

  // The value we represent.
  slot singleton-value :: <eql-ct-value>,
    required-init-keyword: singleton-value:;
end class;

define method print-object (sing :: <singleton-ctype>, stream :: <stream>)
    => ();
  pprint-fields(sing, stream, value: sing.singleton-value);
end;

define method csubtype-dispatch(type1 :: <singleton-ctype>, type2 :: <ctype>)
    => result :: <boolean>;
  csubtype?(type1.base-class, type2);
end method;

// The method is only necessary because which of the previous method and
// the <limited-ctype>,<cclass> method is applicable is ambiguous when
// given a singleton and a class.
//
define method csubtype-dispatch(type1 :: <singleton-ctype>, type2 :: <cclass>)
    => result :: <boolean>;
  csubtype?(type1.base-class, type2);
end method;


//// Class Precedence List computation

// This class is a temporary data structure used during CPL computation.
define class <class-precedence-description> (<object>)
  //
  // The class this cpd describes the precedence of.
  slot cpd-class :: <cclass>, required-init-keyword: class:;
  //
  // List of cpd's for the direct superclasses.
  slot cpd-supers :: <list>, init-value: #();
  //
  // List of cpd's for classes that have to follow this class.
  slot cpd-after :: <list>, init-value: #();
  //
  // Count of times this cpd appeards in some other cpd's after list.
  slot cpd-count :: <fixed-integer>, init-value: 0;
end class;

define constant compute-cpl = method (cl, superclasses)
  case
    superclasses == #() =>
      list(cl);

    superclasses.tail == #() =>
      pair(cl, superclasses.head.precedence-list);

    otherwise =>
      slow-compute-cpl(cl, superclasses);
  end;
end method;

// Find CPL when there are multiple direct superclasses
define constant slow-compute-cpl = method (cl, superclasses)
  let cpds = #();
  let class-count = 0;
  local
    // find CPD for a class, making a new one if necessary.
    method find-cpd (cl)
      block (return)
	for (x in cpds)
	  if (x.cpd-class == cl)
	    return(x);
	  end;
	end;
	compute-cpd(cl, cl.direct-superclasses);
      end;
    end method,

    method compute-cpd (cl, supers)
      let cpd = make(<class-precedence-description>, class: cl);
      cpds := pair(cpd, cpds);
      class-count := class-count + 1;
      unless (supers == #())
        let prev-super-cpd = find-cpd(supers.head);
	cpd.cpd-supers := pair(prev-super-cpd, cpd.cpd-supers);
	cpd.cpd-after := pair(prev-super-cpd, cpd.cpd-after);
	prev-super-cpd.cpd-count := prev-super-cpd.cpd-count + 1;
	for (super in supers.tail)
	  let super-cpd = find-cpd(super);
	  cpd.cpd-supers := pair(super-cpd, cpd.cpd-supers);
	  cpd.cpd-after := pair(super-cpd, cpd.cpd-after);
	  prev-super-cpd.cpd-after := pair(super-cpd, prev-super-cpd.cpd-after);
	  super-cpd.cpd-count := super-cpd.cpd-count + 2;
	  prev-super-cpd := super-cpd;
	end;
      end unless;
      cpd;
    end method;
      
  let candidates = list(compute-cpd(cl, superclasses));
  let rcpl = #();

  for (index from 0 below class-count)
    if (candidates == #())
      error("Inconsistent CPL");
    end;

    local
      handle (cpd)
        candidates := remove!(candidates, cpd);
	rcpl := pair(cpd.cpd-class, rcpl);
	for (after in cpd.cpd-after)
	  if (zero?(after.cpd-count := after.cpd-count - 1))
	    candidates := pair(after, candidates);
	  end;
	end;
      end method;

    if (candidates.tail == #())
      handle(candidates.head);
    else
      // There is more than one candidate, so pick one.
      block (tie-breaker)
	for (c in rcpl)
	  let supers = c.direct-superclasses;
	  for (candidate in candidates)
	    if (member?(candidate.cpd-class, supers))
	      handle(candidate);
	      tie-breaker();
	    end if;
	  end for;
	end for;
	error("Can't happen.");
      end block;
    end if;
  end for;

  reverse!(rcpl);
end method;


//// Classes:

define abstract class <cclass> (<ctype>, <eql-ct-value>)
  //
  // The name, for printing purposes.
  slot cclass-name :: <name>, required-init-keyword: name:;

  // List of the direct superclasses of this class.
  slot direct-superclasses :: <list>,
       required-init-keyword: direct-superclasses:;

  // Closest primary superclass.
  slot closest-primary-superclass :: <cclass>;

  // True when class is sealed, abstract, and/or primary.
  slot sealed? :: <boolean>, init-keyword: sealed:, init-value: #f;
  slot abstract? :: <boolean>, init-keyword: abstract:, init-value: #f;
  slot primary? :: <boolean>, init-keyword: primary:, init-value: #f;

  // Type describing direct instances of this class.
  slot direct-type :: <direct-instance-ctype>;

  // class precedence list of all classes inherited, including this class and
  // indirectly inherited classes.  Unbound if not yet computed.
  slot precedence-list :: <list>;

  // List of all known subclasses (including this class and indirect
  // subclasses).  If sealed, then this is all of 'em.
  slot subclasses :: <list>, init-value: #();
end class;

define method initialize (obj :: <cclass>, #all-keys)
  obj.direct-type := make(<direct-instance-ctype>, base-class: obj);
  let cpl = compute-cpl(obj, obj.direct-superclasses);
  obj.precedence-list := cpl;
  for (super in cpl)
    super.subclasses := pair(obj, super.subclasses);
  end;
  // Find the closest primary superclass.  Note: we don't have to do any
  // error checking, because that is done for us in defclass.dylan.
  if (obj.primary?)
    obj.closest-primary-superclass := obj;
  else
    let closest = #f;
    for (super in obj.direct-superclasses)
      let primary-super = super.closest-primary-superclass;
      if (~closest | csubtype?(primary-super, closest))
	closest := primary-super;
      end;
    end;
    obj.closest-primary-superclass := closest;
  end;
end;

define method print-object (cclass :: <cclass>, stream :: <stream>) => ();
  pprint-fields(cclass, stream, name: cclass.cclass-name);
end;

define class <primitive-cclass> (<cclass>)
end class;

define class <defined-cclass> (<cclass>)
end class;

define constant subclass? = method
    (type1 :: <cclass>, type2 :: <cclass>) => res :: <boolean>;
  member?(type2, type1.precedence-list);
end method;

define method csubtype-dispatch(type1 :: <cclass>, type2 :: <cclass>)
    => result :: <boolean>;
  subclass?(type1, type2);
end method;

define method csubtype-dispatch
    (type1 :: <direct-instance-ctype>, type2 :: <cclass>)
    => result :: <boolean>;
  subclass?(type1.base-class, type2);
end method;

define method ctype-intersection-dispatch(type1 :: <cclass>, type2 :: <cclass>)
    => (result :: <ctype>, precise :: <boolean>);
  case
    subclass?(type1, type2) => values(type1, #t);
    subclass?(type2, type1) => values(type2, #t);

    type1.sealed? & type2.sealed? =>
      values(reduce(ctype-union, empty-ctype(),
      	            intersection(type1.subclasses, type2.subclasses)),
	     #t);

    otherwise => values(type1, #f);
  end;
end method;

define method ctype-intersection-dispatch
    (type1 :: <cclass>, type2 :: <limited-ctype>)
    => (result :: <ctype>, precise :: <true>);
  values(if (subclass?(type2.base-class, type1)) type2 else empty-ctype() end,
         #t);
end;

define method find-direct-classes(type :: <cclass>) => res :: false-or(<list>);
  if (type.sealed?)
    choose(complement(abstract?), type.subclasses);
  else
    #f;
  end;
end method;


//// make-canonical-singleton:

// Return the ctype equivalent to singleton(object), where object is a
// compile-time value.
define generic make-canonical-singleton (thing :: <ct-value>)
    => res :: <ctype>;

define method make-canonical-singleton (thing :: <ct-value>)
    => res :: <ctype>;
  empty-ctype();
end;

define method make-canonical-singleton (thing :: <eql-ct-value>)
    => res :: <ctype>;
  thing.ct-value-singleton
    | (thing.ct-value-singleton := really-make-canonical-singleton(thing));
end;

define method really-make-canonical-singleton (thing :: <cclass>)
    => res :: <ctype>;
  make(<singleton-ctype>,
       base-class: dylan-value(#"<class>"),
       singleton-value: thing);
end;

define method really-make-canonical-singleton (thing :: <eql-ct-literal>,
					       #next next-method)
    => res :: <ctype>;
  let object = thing.ct-literal-value;
  case
    instance?(object, <integer>) =>
      make(<limited-integer-ctype>,
	   base-class: object-cclass(object),
	   low-bound: object, high-bound: object);
	    
    object == #t => dylan-value(#"<true>");
    object == #f => dylan-value(#"<false>");
    object == #() => dylan-value(#"<empty-list>");
      
    otherwise =>
      make(<singleton-ctype>,
	   base-class: object-cclass(object),
	   singleton-value: thing);
  end;
end method;

define method object-cclass (object :: <true>) => res :: <cclass>;
  dylan-value(#"<true>");
end method;

define method object-cclass (object :: <false>) => res :: <cclass>;
  dylan-value(#"<false>");
end method;

define method object-cclass (object :: <symbol>) => res :: <cclass>;
  dylan-value(#"<symbol>");
end method;

define method object-cclass (object :: <character>) => res :: <cclass>;
  dylan-value(#"<character>");
end method;

define method object-cclass (object :: <byte-character>) => res :: <cclass>;
  dylan-value(#"<byte-character>");
end method;

define method object-cclass (object :: <empty-list>) => res :: <cclass>;
  dylan-value(#"<empty-list>");
end method;

define method object-cclass (object :: <pair>) => res :: <cclass>;
  dylan-value(#"<pair>");
end method;

define method object-cclass (object :: <byte-string>) => res :: <cclass>;
  dylan-value(#"<byte-string>");
end method;

define method object-cclass (object :: <simple-object-vector>) => res :: <cclass>;
  dylan-value(#"<simple-object-vector>");
end method;

define method object-cclass (object :: <fixed-integer>) => res :: <cclass>;
  dylan-value(#"<fixed-integer>");
end method;

define method object-cclass (object :: <extended-integer>)
    => res :: <cclass>;
  dylan-value(#"<extended-integer>");
end method;

define method object-cclass (object :: <single-float>) => res :: <cclass>;
  dylan-value(#"<single-float>");
end method;

define method object-cclass (object :: <double-float>) => res :: <cclass>;
  dylan-value(#"<double-float>");
end method;

define method object-cclass (object :: <extended-float>) => res :: <cclass>;
  dylan-value(#"<extended-float>");
end method;




//// Multi-values types:

///
///    The normal type operations (type-union, csubtype?, etc.) are not allowed
/// on multi-value types.  In most situations in the compiler (such as with
/// values of variables and slots.), we we are manipulating a single value
/// (<ctype> class), and don't have to worry about multi-value types.
///
/// Instead we provide new operations which are analogous to the one-value
/// operations (and delegate to them in the single-value case.)  These
/// operations are optimized for utility rather than exactness, but it is
/// guaranteed that it will be no smaller (no more restrictive) than the
/// precise result.
///
/// With values types such as:
///    values(a0, a1)
///    values(b0, b1)
///
/// We compute the more useful result:
///    values(OP(a0, b0), OP(a1, b1))
///
/// Rather than the precise result:
///    OP(values(a0, a1), values(b0, b1))
///
/// This has the virtue of always keeping the values type specifier outermost
/// (so that it is easily stripped off or decoded), and retains all of the
/// information that is really useful for static type analysis.  We want to
/// know what is always true of each value independently.  It is worthless to
/// know that IF the first value is B0 then the second will be B1.


/// <multi-value-ctype> holds information about values for situations (function
/// return, etc.) where there are more than one value.  We extend the slot
/// accessors to handle the degenerate case of a 1-value <ctype>.
///
/// In order to allow the result of union or intersection of values-types to be
/// represented more precisely, we allow some vagueness in the number of
/// "positional" values.  If we union (Y1, Y2) and (X1), then the positional
/// types are (Y1 union X1, Y2), and the min-values is 1.  Y2 is thus sort of
/// an "optional" result type.
///
define class <multi-value-ctype> (<values-ctype>)

  // Types of each specifically typed value.  Values > than min-values might
  // not actually be returned.
  slot positional-types :: <list>, required-init-keyword: positional-types:;

  // The minimum number of values that will ever be returned (<= to
  // positional-types.)
  slot min-values :: <fixed-integer>, required-init-keyword: min-values:;

  // Type of the rest values; empty-ctype if none.
  slot rest-value-type :: <ctype>, required-init-keyword: rest-value-type:;
end class;


// make-values-ctype  --  Exported
//
// Make a potentially multi-value ctype.  If there is only one value, just
// return that.
//
define constant make-values-ctype = method
  (req :: <list>, rest :: false-or(<ctype>)) => res :: <values-ctype>;

 let nreq = req.size;
 if (nreq == 1 & ~rest)
   req.first;
 else
   make(<multi-value-ctype>, positional-types: req, min-values: nreq,
        rest-value-type: rest | empty-ctype());
	
 end;
end method;

   
define method positional-types(type :: <ctype>) => res :: <list>;
  list(type);
end method;

define method min-values(type :: <ctype>) => res :: <fixed-integer>;
  1;
end;

define method rest-value-type(type :: <ctype>) => res :: <ctype>;
  empty-ctype();
end method;


// Convert a possibly multi-value type for a one-value context.
define generic first-value(type :: <values-ctype>) => res :: <ctype>;

define method first-value(type :: <ctype>) => res :: <ctype>;
  type;
end method;

// If a positional value, return it, otherwise return the union of the rest
// value and false.
define method first-value(type :: <values-ctype>) => res :: <ctype>;
  let types = type.positional-types;
  if (type == #())
    ctype-union(type.rest-value-type, dylan-value(#"<false>"));
  else
    types.head
  end;
end method;


//// Multi-value type operations:

/// Fixed-Values-Op  --  Internal
///
///    Return a list of Operation applied to the types in Types1 and Types2,
/// padding with Rest2 as needed.  Types1 must not be shorter than Types2.  The
/// second value is #t if Operation always returned a true second value.
///
define constant fixed-values-op = method 
    (types1 :: <list>, types2 :: <list>, rest2 :: <ctype>,
     operation :: <function>)
  let exact = #t;
  values(map(method(t1, t2)
  	       let (res, win) = operation(t1, t2);
	       unless (win) exact := #f end;
	       res;
	     end method,
	     types1,
	     concatenate(types2,
	     		 make(<list>, size: types1.size - types2.size,
			      fill: ctype-union(rest2,
						dylan-value(#"<false>"))))),
	 exact);
end method;


/// Args-Type-Op  --  Internal
///
/// If the values count signatures differ, then we produce result with the
/// required value count chosen by Min-Fun when applied to the number of
/// required values in type1 and type2.
///
/// The second value is true if the result is definitely empty or if Operation
/// returned true as its second value each time we called it.  Since we
/// approximate the intersection of values types, the second value being true
/// doesn't mean the result is exact.
///
define constant args-type-op = method
    (type1 :: <values-ctype>, type2 :: <values-ctype>, operation :: <function>,
     min-fun :: <function>)
  if (instance?(type1, <ctype>) & instance?(type2, <ctype>))
    operation(type1, type2);
  else
    let types1 = type1.positional-types;
    let rest1 = type1.rest-value-type;
    let types2 = type2.positional-types;
    let rest2 = type2.rest-value-type;
    let (rest, rest-exact) = operation(rest1, rest2);
    let (res, res-exact) =
        if (types1.size < types2.size)
	  fixed-values-op(types2, types1, rest1, operation);
	else
	  fixed-values-op(types1, types2, rest2, operation);
	end if;
    if (member?(empty-ctype(), res))
      values(empty-ctype(), #t);
    else
      values(make(<multi-value-ctype>, positional-types: res,
          	  min-values: min-fun(type1.min-values, type2.min-values),
		  rest-value-type: rest),
	     res-exact & rest-exact);
    end;
  end;
end method;


/// Values-Type-Union, Values-Type-Intersection  --  Interface
///
///    Do a union or intersection operation on types that might be values
/// types.
///
define constant values-type-union = method
    (type1 :: <values-ctype>, type2 :: <values-ctype>)
    => res :: <values-ctype>;
  args-type-op(type1, type2, ctype-union, min);
end method;
///
define constant values-type-intersection = method
    (type1 :: <values-ctype>, type2 :: <values-ctype>)
    => res :: <values-ctype>;
  args-type-op(type1, type2, ctype-intersection, max);
end method;


/// Values-Types-Intersect?  --  Interface
///
///    Like CTypes-Intersect?, except that it sort of works on values types.
/// Note that due to the semantics of Values-Type-Intersection, this might
/// return {T, T} when there isn't really any intersection (?).
///
define constant values-types-intersect? = method
    (type1 :: <values-ctype>, type2 :: <values-ctype>)
    => (result :: <boolean>, precise :: <boolean>);

  case
    type1 == empty-ctype() | type2 == empty-ctype() => values(#t, #t);

    instance?(type1, <multi-value-ctype>) |
    instance?(type2, <multi-value-ctype>) =>
      let (res, win) = values-type-intersection(type1, type2);
      values(~(res == empty-ctype()), win);

    otherwise => ctypes-intersect?(type1, type2);
  end;
end method;


/// Values-Subtype?  --  Interface
///
///    A subtypep-like operation that can be used on any types, including
/// values types.  This is something like the result type congruence rule.
///
define constant values-subtype? = method
    (type1 :: <values-ctype>, type2 :: <values-ctype>)
    => (result :: <boolean>, precise :: <boolean>);

  case
    instance?(type1, <ctype>) & instance?(type2, <ctype>) =>
      csubtype?(type1, type2);

    ~values-types-intersect?(type1, type2) => values(#f, #t);

    otherwise =>
      let types1 = type1.positional-types;
      let rest1 = type1.rest-value-type;
      let types2 = type2.positional-types;
      let rest2 = type2.rest-value-type;
      case
        type1.min-values < type2.min-values => values(#f, #t);
	types1.size < types2.size => values(#f, #f);
	block (done)
	  for (t1 in types1, t2 in types2)
	    let (res, win-p) = csubtype?(t1, t2);
	    unless (win-p) done(#f, #f) end;
	    unless (res) done(#f, #t) end;
	  end for;
	  csubtype?(rest1, rest2);
	end block;
      end;
  end;
end method;


//// Accessors.

define variable *wild-ctype-memo* = #f;

define constant wild-ctype
  = method ()
      *wild-ctype-memo*
	| (*wild-ctype-memo*
	     := make(<multi-value-ctype>,
		     positional-types: #(),
		     rest-value-type: object-ctype(),
		     min-values: 0));
    end;

define variable *object-ctype-memo* = #f;

define constant object-ctype
  = method ()
      *object-ctype-memo*
	| (*object-ctype-memo*
	     := dylan-value(#"<object>") | error("<object> undefined?"));
    end;

define variable *function-ctype-memo* = #f;

define constant function-ctype
  = method ()
      *function-ctype-memo*
	| (*function-ctype-memo*
	     := dylan-value(#"<function>") | error("<function> undefined?"));
    end;

define variable *class-ctype-memo* = #f;

define constant class-ctype
  = method ()
      *class-ctype-memo*
	| (*class-ctype-memo*
	     := dylan-value(#"<class>") | error("<class> undefined?"));
    end;

define variable *empty-ctype-memo* = #f;

// The empty-type (bottom) is the union of no members.
define constant empty-ctype
  = method ()
      *empty-ctype-memo*
	| (*empty-ctype-memo* := make(<union-ctype>,
				      members: #(),
				      type-hash: 0));
    end;
