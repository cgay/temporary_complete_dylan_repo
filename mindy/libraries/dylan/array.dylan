module:   dylan
language: infix-dylan
author:   Nick Kramer (nkramer@cs.cmu.edu)

//////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 1994, Carnegie Mellon University
//  All rights reserved.
//
//  This code was produced by the Gwydion Project at Carnegie Mellon
//  University.  If you are interested in using this code, contact
//  "Scott.Fahlman@cs.cmu.edu" (Internet).
//
//////////////////////////////////////////////////////////////////////
//
//  $Header: /home/housel/work/rcs/gd/src/mindy/libraries/dylan/array.dylan,v 1.2 1994/05/31 18:12:07 nkramer Exp $
//

/*
 * This is an array implementation that depends upon vectors being
 * implemented.
 */

/* ------------- */

define constant no-default = list (#"no-default");

/* ------------- */

define class <multiD-array> (<array>)
  slot dimensions-slot  :: <simple-object-vector>;  // Sequence of integers
  slot contents-slot    :: <simple-object-vector>;
  slot size-slot        :: <integer>;
end class <multiD-array>;

/* ------------- */

// Array stuff


define method make (c :: singleton (<array>), 
		    #key dimensions: dimensions :: <sequence> = no-default,
		    fill: fill = #f);

  if (dimensions == no-default)
    error ("Need the dimensions or a size for an array");
  elseif (size (dimensions) = 1)
    make (<vector>, fill: fill, size: head (dimensions));
  else
    make (<multiD-array>, dimensions: dimensions, fill: fill);
  end if;
end method make;

/* ------------- */

define method row-major-index (array :: <array>, #rest indices)
                       => index :: <integer>;
  let dims = dimensions (array);
  let sum = 0;

  if ( size (indices) ~= size (dims) )
    error ( "Number of indices not equal to rank. Got %=, wanted %d indices",
	   indices, size (dims) );
  else
    for (index in indices,
	 dim   in dims)
      if (index < 0 | index >= dim)
	error ("Array index out of bounds: %= in %=", index, indices);
      else
	sum := (sum * dim) + index;
      end if;
    end for;

    sum;
  end if;
end method row-major-index;	       

/* ------------- */

define method aref (array :: <array>, #rest indices)
  let index = apply (row-major-index, array, indices);

  array [index];             // Call element
end method aref;

/* ------------- */

define method aref-setter (value, array :: <array>, #rest indices);
  let index = apply (row-major-index, array, indices);

  array [index] := value;    // Call element-setter
end method aref-setter;

/* ------------- */

// rank -- the number of dimensions

define method rank (array :: <array>) => the-rank-of-array :: <integer>;
  size (dimensions (array));
end method rank;

/* ------------- */

// Also defined below on multiD-arrays

define method size (array :: <array>) => size :: <integer>;
  reduce (\*, 1, dimensions (array));
end method size;

/* ------------- */

define method dimension (array :: <array>, axis :: <integer>) 
             => dim-of-that-axis :: <integer>;
  (dimensions (array)) [axis];
end method dimension;

/* ------------- */

define method forward-iteration-protocol (array :: <array>)
  => (initial-state          :: <integer>,   limit           :: <integer>,
      next-state             :: <function>,  finished-state? :: <function>,
      current-key            :: <function>,  current-element :: <function>,
      current-element-setter :: <function>,  copy-state      :: <function>);

  values ( 0,                 // initial state
	   size (array),      // limit 

	      // next-state
	   method (array :: <array>, state :: <integer>)    
	     state + 1;
	   end method,

	     // finished-state?
	   method (array :: <array>, state :: <integer>, limit :: <integer>)
	     state = limit;
	   end method,

	     // current-key
	   method (array :: <array>, state :: <integer>) => key :: <integer>;
	     state;
	   end method,

	     // current-element
	  method (array :: <array>, state :: <integer>)
	    array [state];
	  end method,

	    // current-element-setter
	  method (value, array :: <array>, state :: <integer>)
	    array [state] := value;
	  end method,

	    // copy-state
	  method (array :: <array>, state :: <integer>) 
	       => new-state :: <integer>;
	    state;
	  end method
	);
end method forward-iteration-protocol;

/* ------------- */

define method backward-iteration-protocol (array :: <array>)
  => (final-state            :: <integer>,   limit           :: <integer>,
      previous-state         :: <function>,  finished-state? :: <function>,
      current-key            :: <function>,  current-element :: <function>,
      current-element-setter :: <function>,  copy-state      :: <function>);

  values ( size (array) - 1,                 // final state
	   -1,                                // limit 

	      // next-state
	   method (array :: <array>, state :: <integer>)    
	     state - 1;
	   end method,

	     // Everything else the same as forward-iteration-protocol

	     // finished-state?
	   method (array :: <array>, state :: <integer>, limit :: <integer>)
	     state = limit;
	   end method,

	     // current-key
	   method (array :: <array>, state :: <integer>) => key :: <integer>;
	     state;
	   end method,

	     // current-element
	  method (array :: <array>, state :: <integer>)
	    array [state];
	  end method,

	    // current-element-setter
	  method (value, array :: <array>, state :: <integer>)
	    array [state] := value;
	  end method,

	    // copy-state
	  method (array :: <array>, state :: <integer>) 
	       => new-state :: <integer>;
	    state;
	  end method
	);
end method backward-iteration-protocol;

/* ------------- */

// multiD-array code

define method initialize (array :: <multiD-array>, 
			  #key dimensions: dimensions :: <sequence>,
			  fill: fill = #f);

  if ( size (dimensions) == 1 )
    // This code should never be executed unless someone calls
    // make on a <multiD-array> instead of make (<array>)

    error ("Can't make a <multiD-array> with 1 dimension");
  end if;

  array.dimensions-slot := as (<simple-object-vector>, dimensions);

  let total-size = reduce (\*, 1, array.dimensions-slot);
  array.size-slot := total-size;

  array.contents-slot := make (<simple-object-vector>, 
			       size: total-size, fill: fill);
end method initialize;

/* ------------- */

define method element (array :: <multiD-array>, index :: <integer>,
		       #key default: default = no-default);
  if (default == no-default)
    array.contents-slot [index];
  else
    element (array.contents-slot, index, default: default);
  end if;
end method element;

/* ------------- */

define method element-setter (value, array :: <multiD-array>, 
			      index :: <integer>);
  array.contents-slot [index] := value;
end method element-setter;

/* ------------- */

define method size (array :: <multiD-array>) => size :: <integer>;
  array.size-slot;
end method size;

/* ------------- */

define method class-for-copy (c :: singleton (<multiD-array>)) 
                  => array :: <class>;
  <array>;
end method class-for-copy;

/* ------------- */

define method dimensions (array :: <multiD-array>) => dimensions :: <sequence>;
  array.dimensions-slot;
end method dimensions;

