rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/runtime/dylan/list.dylan,v 1.2 1995/11/13 23:09:07 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.
module: dylan-viscera

define abstract class <list> (<mutable-sequence>)
  sealed slot head :: <object>, setter: %head-setter,
    required-init-keyword: head:;
  sealed slot tail :: <object>, setter: %tail-setter,
    required-init-keyword: tail:;
end;

define sealed method make (class == <list>, #key size = 0, fill = #f)
    => res :: <list>;
  for (i :: <fixed-integer> from 0 below size,
       result = #() then pair(fill, result))
  finally
    result;
  end;
end;

define class <empty-list> (<list>)
end;

define sealed method make (class == <empty-list>, #key) => res :: type-or();
  error("Can't make new instances of <empty-list>, #() is it.");
end;

define class <pair> (<list>)
end;

seal generic make (singleton(<pair>));
seal generic initialize (<pair>);

define inline method head-setter (new, pair :: <pair>) => new;
  pair.%head := new;
end;

define inline method tail-setter (new, pair :: <pair>) => new;
  pair.%tail := new;
end;

define sealed inline method forward-iteration-protocol (list :: <list>)
    => (initial-state :: <list>,
	limit :: <list>,
	next-state :: <function>,
	finished-state? :: <function>,
	current-key :: <function>,
	current-element :: <function>,
	current-element-setter :: <function>,
	copy-state :: <function>);
  values(list,
	 #(),
	 method (list :: <list>, state :: <list>)
	   state.tail;
	 end,
	 method (list :: <list>, state :: <list>, limit :: <list>)
	   state == limit;
	 end,
	 method (list :: <list>, state :: <pair>)
	   block (return)
	     for (key :: <fixed-integer> from 0,
		  pair :: <pair> = list then pair.tail,
		  until: pair == state)
	     finally
	       key;
	     end;
	   end;
	 end,
	 method (list :: <list>, state :: <pair>)
	   state.head;
	 end,
	 method (new-value :: <object>, list :: <list>, state :: <pair>)
	   state.head := new-value;
	 end,
	 method (list :: <list>, state :: <list>)
	   state;
	 end);
end;

define flushable inline method pair (head, tail)
    => res :: <pair>;
  make(<pair>, head: head, tail: tail);
end;

define flushable method list (#rest args)
    => res :: <list>;
  as(<list>, args);
end;

define inline sealed method as (class == <list>, list :: <list>)
    => res :: <list>;
  list;
end;

define flushable sealed method as
    (class == <list>, vec :: <simple-object-vector>)
    => res :: <list>;
  for (index :: <fixed-integer> from vec.size - 1 to 0 by -1,
       res = #() then pair(vec[index], res))
  finally
    res;
  end;
end;

define flushable sealed method as
    (class == <list>, collection :: <collection>)
    => res :: <list>;
  for (results = #() then pair(element, results),
       element in collection)
  finally
    reverse!(results);
  end;
end;

define sealed inline method empty? (list :: <list>) => res :: <boolean>;
  list == #();
end;

define sealed inline method add! (list :: <list>, element)
    => res :: <pair>;
  pair(element, list);
end;

define sealed method remove! (list :: <list>, element, #key test = \==, count)
    => res :: <list>;
  let prev = #f;
  let removed = 0;
  block (return)
    for (remaining = list then remaining.tail,
	 until: remaining == #())
      if (test(remaining.head, element))
	if (prev)
	  prev.tail := remaining.tail;
	else
	  list := remaining.tail;
	end;
	removed := removed + 1;
	if (removed == count)
	  return();
	end;
      else
	prev := remaining;
      end;
    end;
  end;
  list;
end;

define sealed method size (list :: <list>)
    => res :: union(<false>, <fixed-integer>);
  if (list == #())
    0;
  elseif (list.tail == #())
    1;
  else
    block (return)
      for (slow :: <list> = list.tail then slow.tail,
	   fast :: <list> = list.tail.tail then fast.tail.tail,
	   result from 2 by 2)
	if (slow == fast)
	  return(#f);
	elseif (fast == #())
	  return(result);
	elseif (fast.tail == #())
	  return(result + 1);
	end;
      end;
    end;
  end;
end;

define flushable sealed method reverse (list :: <list>) => res :: <list>;
  for (results = #() then pair(element, results),
       element in list)
  finally
    results;
  end;
end;

define sealed method reverse! (list :: <list>) => res :: <list>;
  let temp :: <list> = #();
  for (remaining :: <list> = list then temp,
       results :: <list> = #() then remaining,
       until: remaining == #())
    temp := remaining.tail;
    remaining.tail := results;
  finally
    results;
  end;
end;


define sealed method \= (list1 :: <list>, list2 :: <list>)
    => res :: <boolean>;
  if (list1 == list2)
    #t;
  elseif (list1 == #() | list2 == #())
    #f;
  else
    list1.head = list2.head & list1.tail = list2.tail;
  end;
end;

define sealed method \= (list :: <list>, sequence :: <sequence>)
    => res :: <boolean>;
  block (return)
    for (remaining = list then remaining.tail,
	 object in sequence)
      if (~instance?(remaining, <pair>))
	return(#f);
      elseif (remaining.head ~= object)
	return(#f);
      end;
    finally
      remaining == #();
    end;
  end;
end;

define sealed inline method \= (sequence :: <sequence>, list :: <list>)
    => res :: <boolean>;
  list = sequence;
end;

seal generic member? (<object>, <list>);
