module: heap

define class <state> (<object>)
  slot stream :: <stream>, required-init-keyword: stream:;
  slot output-info :: <output-info>, required-init-keyword: output-info:;
  slot next-id :: <fixed-integer>, init-value: 0;
  slot object-queue :: <deque>, init-function: curry(make, <deque>);
  slot object-names :: <table>, init-function: curry(make, <table>);
  slot symbols :: union(<literal-false>, <literal-symbol>),
    init-function: curry(make, <literal-false>);
end;

define method build-initial-heap
    (roots :: <vector>, stream :: <stream>, output-info :: <output-info>)
    => ();
  let state = make(<state>, stream: stream, output-info: output-info);
  format(stream, "\t.data\n\t.align\t8\n\t.export\troots, DATA\nroots");
  for (ctv in roots, index from 0)
    spew-reference(ctv, $general-rep, format-to-string("roots[%d]", index),
		   state);
  end;
  until (state.object-queue.empty?)
    let object = pop(state.object-queue);
    format(stream, "\n; %s\n\t.align\t8\n%s",
	   object, state.object-names[object]);
    spew-object(object, state);
  end;
  format(stream,
	 "\n\n\t.align\t8\n\t.export\tinitial_symbols, DATA\n"
	   "initial_symbols\n");
  spew-reference(state.symbols, $heap-rep, "Initial Symbols", state);
end;


define generic spew-reference
    (object :: false-or(<ct-value>), rep :: <representation>,
     tag :: <byte-string>, state :: <state>)
    => ();

define method spew-reference
    (object :: <false>, rep :: <representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.blockz\t%d\t; %s\n", rep.representation-size, tag);
end;

define method spew-reference
    (object :: <literal>, rep :: <immediate-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  let bits = raw-bits(object);
  select (rep.representation-size)
    1 => format(state.stream, "\t.byte\t%d\t; %s\n", bits, tag);
    2 => format(state.stream, "\t.half\t%d\t; %s\n", bits, tag);
    4 => format(state.stream, "\t.word\t%d\t; %s\n", bits, tag);
    8 =>
      format(state.stream, "\t.word\t%d, %d\t; %s\n",
	     ash(bits, -32),
	     logand(bits, ash(as(<extended-integer>, 1), 32) - 1),
	     tag)
  end;
end;

define method spew-reference
    (object :: <ct-value>, rep :: <general-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  let cclass = object.ct-value-cclass;
  let best-rep = pick-representation(cclass, #"speed");
  let (heapptr, dataword)
    = if (instance?(best-rep, <data-word-representation>))
	values(make(<proxy>, for: cclass), raw-bits(object));
      else
	values(object, 0);
      end;
  format(state.stream, "\t.word\t%s, %d\t; %s\n",
	 object-name(heapptr, state),
	 dataword, tag);
end;

define method spew-reference
    (object :: <proxy>, rep :: <general-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.word\t%s, 0\t; %s\n",
	 object-name(object, state), tag);
end;

define method spew-reference
    (object :: <ct-value>, rep == $heap-rep,
     tag :: <byte-string>, state :: <state>) => ();
  format(state.stream, "\t.word\t%s\t; %s\n", object-name(object, state), tag);
end;

define method spew-reference
    (object :: <ct-entry-point>, rep :: <immediate-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.word\t%s\t; %s\n", object-name(object, state), tag);
end;

define method spew-reference
    (object :: <ct-entry-point>, rep :: <general-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.word\t%s, %s\t; %s\n",
	 object-name(make(<proxy>, for: object.ct-value-cclass), state),
	 object-name(object, state), tag);
end;


define method object-name (object :: <ct-value>, state :: <state>)
    => name :: <string>;
  element(state.object-names, object, default: #f)
    | begin
	let name = format-to-string("L%d", state.next-id);
	state.next-id := state.next-id + 1;
	element(state.object-names, object) := name;
	push-last(state.object-queue, object);
	name;
      end;
end;

define method object-name (object :: <ct-entry-point>, state :: <state>)
    => name :: <string>;
  element(state.object-names, object, default: #f)
    | begin
	let name = entry-point-c-name(object, state.output-info);
	format(state.stream, "\t.import\t%s, code\n", name);
	element(state.object-names, object) := name;
	name;
      end;
end;
	


define generic raw-bits (ctv :: <literal>) => res :: <integer>;

define method raw-bits (ctv :: <literal-true>) => res :: <integer>;
  1;
end;

define method raw-bits (ctv :: <literal-false>) => res :: <integer>;
  0;
end;

define method raw-bits (ctv :: <literal-fixed-integer>) => res :: <integer>;
  ctv.literal-value;
end;

define method raw-bits (ctv :: <literal-single-float>) => res :: <integer>;
  raw-bits-for-float(ctv.literal-value, 24, 127, 8);
end;

define method raw-bits (ctv :: <literal-double-float>) => res :: <integer>;
  raw-bits-for-float(ctv.literal-value, 53, 1023, 11);
end;

define method raw-bits (ctv :: <literal-extended-float>) => res :: <integer>;
  // ### gcc doesn't use extended floats for long doubles.
  // raw-bits-for-float(ctv.literal-value, 113, 16383, 15);
  raw-bits-for-float(ctv.literal-value, 53, 1023, 11);
end;

define method raw-bits (ctv :: <literal-character>) => res :: <integer>;
  as(<integer>, ctv.literal-value);
end;

define method raw-bits-for-float
    (ctv :: <literal-float>, precision :: <fixed-integer>,
     bias :: <fixed-integer>, exponent-bits :: <fixed-integer>)
    => res :: <integer>;
  let num = as(<ratio>, ctv.literal-value);
  if (zero?(num))
    0;
  else
    let (num, neg?)
      = if (negative?(num))
	  values(-num, #t);
	else
	  values(num, #f);
	end;
    let (exponent, fraction)
      = if (num >= 1)
	  for (exponent from 1,
	       fraction = num / 2 then fraction / 2,
	       while: fraction >= 1)
	  finally
	    values(exponent, fraction);
	  end;
	else
	  for (exponent from 0 by -1,
	       fraction = num then fraction * 2,
	       while: fraction < ratio(1,2))
	  finally
	    values(exponent, fraction);
	  end;
	end;
    let biased-exponent = exponent + bias;
    if (biased-exponent >= ash(1, exponent-bits))
      // Overflow.
      error("%s is too big.", ctv);
    end;
    if (biased-exponent <= 0)
      if (-biased-exponent >= precision - 1)
	// Underflow.
	error("%s is too small.", ctv);
      end;
      fraction := fraction / ash(1, -biased-exponent);
      biased-exponent := 0;
    end;
    let shifted-fraction
      = round/(ash(numerator(fraction), precision),
	       denominator(fraction));
    let bits = logior(ash(as(<extended-integer>, biased-exponent),
			  precision - 1),
		      logand(shifted-fraction,
			     ash(as(<extended-integer>, 1), precision - 1)
			       - 1));
    if (neg?)
      logior(bits,
	     ash(as(<extended-integer>, 1),
		 precision + exponent-bits - 1));
    else
      bits;
    end;
  end;
end;


define generic spew-object (object :: <ct-value>, state :: <state>) => ();


define method spew-object
    (object :: <literal-boolean>, state :: <state>) => ();
  spew-instance(object.ct-value-cclass, state);
end;

define method spew-object
    (object :: <literal-extended-integer>, state :: <state>) => ();
  let digits = make(<stretchy-vector>);
  local
    method repeat (remainder :: <integer>);
      let (remainder :: <integer>, digit :: <integer>)
	= floor/(remainder, 256);
      add!(digits, make(<literal-fixed-integer>, value: digit));
      unless (if (logbit?(7, digit))
		remainder = -1;
	      else
		remainder = 0;
	      end)
	repeat(remainder);
      end;
    end;
  repeat(object.literal-value);
  spew-instance(specifier-type(#"<extended-integer>"), state,
		bignum-size: as(<ct-value>, digits.size),
		bignum-digit: digits);
end;

define method spew-object (object :: <literal-ratio>, state :: <state>) => ();
  let num = as(<ratio>, object.literal-value);
  spew-instance(object.ct-value-cclass, state,
		numerator:
		  make(<literal-extended-integer>, num.numerator),
		denominator:
		  make(<literal-extended-integer>, num.denominator));
end;

define method spew-object (object :: <literal-float>, state :: <state>) => ();
  spew-instance(object.ct-value-cclass, state, value: object);
end;

define method spew-object
    (object :: <literal-symbol>, state :: <state>) => ();
  spew-instance(specifier-type(#"<symbol>"), state,
		symbol-string:
		  as(<ct-value>, as(<string>, object.literal-value)),
		symbol-next: state.symbols);
  state.symbols := object;
end;

define method spew-object
    (object :: <literal-pair>, state :: <state>) => ();
  spew-instance(specifier-type(#"<pair>"), state,
		head: object.literal-head,
		tail: object.literal-tail);
end;

define method spew-object
    (object :: <literal-empty-list>, state :: <state>) => ();
  spew-instance(specifier-type(#"<empty-list>"), state,
		head: object, tail: object);
end;

define method spew-object
    (object :: <literal-simple-object-vector>, state :: <state>) => ();
  let contents = object.literal-value;
  spew-instance(specifier-type(#"<simple-object-vector>"), state,
		size: as(<ct-value>, contents.size),
		%element: contents);
end;

define method spew-object
    (object :: <literal-string>, state :: <state>) => ();
  let str = object.literal-value;
  spew-instance(specifier-type(#"<byte-string>"), state,
		size: as(<ct-value>, str.size),
		%element: map-as(<vector>, curry(as, <ct-value>), str));
end;

define method spew-object
    (object :: <union-ctype>, state :: <state>) => ();
  let mems = #();
  let sings = #();
  for (member in object.members)
    if (instance?(member, <singleton-ctype>))
      sings := pair(member.singleton-value, sings);
    else
      mems := pair(member, mems);
    end;
  end;
  spew-instance(specifier-type(#"<union>"), state,
		union-members: make(<literal-list>,
				    contents: mems,
				    sharable: #t),
		union-singletons: make(<literal-list>,
				       contents: sings,
				       sharable: #t));
end;

define method spew-object
    (object :: <limited-integer-ctype>, state :: <state>) => ();
  local method make-lit (x :: false-or(<integer>))
	  if (x == #f)
	    as(<ct-value>, x);
	  elseif (x < runtime-$minimum-fixed-integer
		    | x > runtime-$maximum-fixed-integer)
	    make(<literal-extended-integer>, value: x);
	  else
	    make(<literal-fixed-integer>, value: x);
	  end;
	end;
  spew-instance(specifier-type(#"<limited-integer>"), state,
		limited-integer-base-class: object.base-class,
		limited-integer-minimum: make-lit(object.low-bound),
		limited-integer-maximum: make-lit(object.high-bound));
end;

define method spew-object
    (object :: <singleton-ctype>, state :: <state>) => ();
  spew-instance(specifier-type(#"<singleton>"), state,
		singleton-object: object.singleton-value);
end;

define method spew-object
    (object :: <byte-character-ctype>, state :: <state>) => ();
  spew-instance(specifier-type(#"<byte-character-type>"), state);
end;

define method spew-object
    (object :: <defined-cclass>, state :: <state>) => ();
  let defn = object.class-defn;
  spew-instance(specifier-type(#"<class>"), state,
		debug-name:
		  make(<literal-symbol>,
		       value: object.cclass-name.name-symbol),
		unique-id:
		  as(<ct-value>, object.unique-id | -1),
		direct-superclasses:
		  make(<literal-simple-object-vector>,
		       contents: object.direct-superclasses,
		       sharable: #t),
		all-superclasses:
		  make(<literal-simple-object-vector>,
		       contents: object.precedence-list,
		       sharable: #t),
		closest-primary-superclass: object.closest-primary-superclass,
		direct-subclasses:
		  make(<literal-list>, contents: object.direct-subclasses),
		class-functional?: as(<ct-value>, object.functional?),
		class-primary?: as(<ct-value>, object.primary?),
		class-abstract?: as(<ct-value>, object.abstract?),
		class-sealed?: as(<ct-value>, object.sealed?),
		class-defered-evaluations:
		  defn.class-defn-defered-evaluations-function
		  | as(<ct-value>, #f),
		class-maker: defn.class-defn-maker-function
		  | as(<ct-value>, #f));
end;

define method spew-object (object :: <proxy>, state :: <state>) => ();
  spew-reference(object.proxy-for, $heap-rep, "%object-class", state);
end;

define method spew-object (object :: <ct-function>, state :: <state>) => ();
  spew-function(object, state,
		general-entry:
		  make(<ct-entry-point>, for: object, kind: #"general"));
end;

define method spew-object
    (object :: <ct-generic-function>, state :: <state>) => ();
  let defn = object.ct-function-definition;
  spew-function(object, state,
		general-entry:
		  begin
		    let discriminator = defn.generic-defn-discriminator;
		    if (discriminator)
		      make(<ct-entry-point>, for: discriminator,
			   kind: #"general");
		    else
		      let dispatch = dylan-defn(#"gf-call");
		      if (dispatch)
			make(<ct-entry-point>,
			     for: dispatch.ct-value,
			     kind: #"main");
		      else
			#f;
		      end;
		    end;
		  end,
		generic-function-methods:
		  make(<literal-list>,
		       contents:
			 remove(map(ct-value, generic-defn-methods(defn)), #f),
		       sharable: #f));
end;

define method spew-object (object :: <ct-method>, state :: <state>) => ();
  spew-function(object, state,
		general-entry:
		  if (object.ct-method-hidden?)
		    let tramp = dylan-defn(#"general-call");
		    if (tramp)
		      make(<ct-entry-point>,
			   for: tramp.ct-value,
			   kind: #"main");
		    else
		      #f;
		    end;
		  else
		    make(<ct-entry-point>, for: object, kind: #"general");
		  end,
		generic-entry:
		  make(<ct-entry-point>, for: object, kind: #"generic"));
end;

define method spew-function
    (func :: <ct-function>, state :: <state>, #rest slots) => ();
  let sig = func.ct-function-signature;
  let returns = sig.returns;
  let positionals = returns.positional-types;
  let min-values = returns.min-values;
  apply(spew-instance, func.ct-value-cclass, state,
	function-specializers:
	  make(<literal-simple-object-vector>,
	       contents: sig.specializers,
	       sharable: #t),
	function-rest?: as(<ct-value>, sig.rest-type & #t),
	function-keywords:
	  if (sig.key-infos)
	    make(<literal-simple-object-vector>,
		 contents: map(compose(curry(as, <ct-value>), key-name),
			       sig.key-infos),
		 sharable: #t);
	  else
	    as(<ct-value>, #f);
	  end,
	function-all-keys?: as(<ct-value>, sig.all-keys?),
	function-values:
	  make(<literal-simple-object-vector>,
	       contents: copy-sequence(positionals, end: min-values),
	       sharable: #t),
	function-rest-value:
	  reduce(ctype-union, returns.rest-value-type,
		 copy-sequence(positionals, start: min-values)),
	slots);
end;


define method spew-instance
    (class :: <cclass>, state :: <state>, #rest slots) => ();
  if (class.abstract?)
    error("Spewing an abstract class?");
  end;
  let layout = class.instance-slots-layout;
  let fields = make(<vector>, size: layout.layout-length + 1, fill: #f);
  for (slot in class.all-slot-infos)
    if (instance?(slot, <instance-slot-info>))
      block (return)
	for (entry in slot.slot-positions)
	  if (csubtype?(class, entry.head))
	    fields[entry.tail] := slot;
	    return();
	  end;
	end;
	error("Can't find the position for %= in %=?", slot, class);
      end;
    end;
  end;
  for (hole in layout.layout-holes)
    fields[hole.head] := hole.tail;
  end;
  for (field in fields)
    select (field by instance?)
      <false> => #f;
      <fixed-integer> =>
	format(state.stream, "\t.blockz\t%d\n", field);
      <instance-slot-info> =>
	let init-value = find-init-value(class, field, slots);
	let getter = field.slot-getter;
	let name = if (getter)
		     as(<string>, getter.variable-name);
		   else
		     "???";
		   end;
	if (instance?(field, <vector-slot-info>))
	  let len-ctv = find-init-value(class, field.slot-size-slot, slots);
	  unless (len-ctv)
	    compiler-warning("Length of a variable length instance"
			       " unspecified?");
	    len-ctv := as(<ct-value>, 0);
	  end;
	  unless (instance?(len-ctv, <literal-fixed-integer>))
	    error("Bogus length: %=", len-ctv);
	  end;
	  let len = len-ctv.literal-value;
	  if (instance?(init-value, <sequence>))
	    unless (init-value.size == len)
	      error("Size mismatch.");
	    end;
	    for (element in init-value,
		 index from 0)
	      spew-reference(element, field.slot-representation,
			     format-to-string("%s[%d]", name, index),
			     state);
	    end;
	  else
	    for (i from 0 below len)
	      spew-reference(init-value, field.slot-representation,
			     format-to-string("%s[%d]", name, i),
			     state);
	    end;
	  end;
	else
	  spew-reference(init-value, field.slot-representation, name, state);
	end;
    end;
  end;
end;

define method find-init-value
    (class :: <cclass>, slot :: <instance-slot-info>,
     slots :: <simple-object-vector>)
    => res :: type-or(<ct-value>, <sequence>, <false>);
  block (return)
    let getter = slot.slot-getter;
    let slot-name = getter & getter.variable-name;
    if (getter)
      for (index from 0 below slots.size by 2)
	if (slots[index] == slot-name)
	  return(slots[index + 1]);
	end;
      end;
    end;
    for (override in slot.slot-overrides)
      if (csubtype?(class, override.override-introduced-by))
	if (override.override-init-value == #t
	      | override.override-init-function)
	  compiler-warning("Init value for %s in %= not set up.",
			   slot-name, class);
	  return(#f);
	end;
	return(override.override-init-value);
      end;
    end;
    if (slot.slot-init-value == #t | slot.slot-init-function)
      compiler-warning("Init value for %s in %= not set up.",
		       slot-name, class);
    end;
    slot.slot-init-value;
  end;
end;

