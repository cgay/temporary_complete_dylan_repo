Module: flow
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/control-flow.dylan,v 1.14 1995/06/07 15:23:44 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.


/*
region [source-location-mixin] {abstract}
    block-region-mixin {abstract}
        component

    linear-region {abstract}
        simple-region
        compound-region
	    empty-region

    join-region {abstract}
        if-region [dependent-mixin]
	body-region {abstract}
	    block-region [block-region-mixin, queueable-mixin, annotatable]
	    function-region
	    loop-region

    exit
	return

*/

define abstract class <region> (<source-location-mixin>)
  //
  // The region that directly encloses this one.  #f in components (which form
  // the root of the tree.)
  slot parent :: false-or(<region>), init-keyword: parent:, init-value: #f;
end class;


// <linear-regions> contain code but don't introduce any join points (phi
// functions) in themselves.  Of course, a compound region can have anything
// inside it.
//
define abstract class <linear-region> (<region>)
end class;

// <simple-region> is a sequence of assignments (i.e. expression evaluations
// without any significant control flow changes.)
//
define class <simple-region> (<linear-region>)
  //
  // Double-linked list of assignments.
  slot first-assign :: false-or(<abstract-assignment>), init-value: #f;
  slot last-assign :: false-or(<abstract-assignment>), init-value: #f;
end class;

// <compound-region> is a sequence of arbitrary regions.
//
define class <compound-region> (<linear-region>)
  //
  // The nested regions, in order of evaluation.
  slot regions :: <list>, required-init-keyword: regions:;
end class;

define method make (class == <compound-region>,
		    #next next-method, #rest keys, #key regions)
  let regions = choose(complement(rcurry(instance?, <empty-region>)), regions);
  if (empty?(regions))
    apply(make, <empty-region>, regions: regions, keys);
  else
    apply(next-method, class, regions: regions, keys);
  end;
end;

define class <empty-region> (<compound-region>)
  keyword regions:, init-value: #();
end;


// Join-Regions:
//
// Subclasses of <join-region> describe control flow that have branches
// or joins.
//
define class <join-region> (<region>)
  //
  // Region containing join-assignments for this region.
  slot join-region :: <simple-region>;
end class;

// An <if-region> represents a conditional test.  The join function joins the
// values of the two branches.
//
define class <if-region> (<join-region>, <dependent-mixin>)
  //
  // Holds the dependency for the leaf whose value is tested.
  inherited slot depends-on;
  //
  // Regions holding the branches of the IF.
  slot then-region :: <region>, init-keyword: then-region:;
  slot else-region :: <region>, init-keyword: else-region:;
end class;

// A join-region that contains only one "body" region (no branching, only
// joins.)
//
define class <body-region> (<join-region>)
  slot body :: <region>, init-keyword: body:;
end;

// Inherited by things that can have exits to them (blocks and components.)
//
define class <block-region-mixin> (<region>)
  //
  // Chain of all the exits to this block, threaded though exit-next.
  slot exits :: false-or(<exit>), init-value: #f;
end;

// A <block-region> wraps code which can exit to its endpoint.  The phi
// function joins the values arriving at the endpoint.
//
define class <block-region>
    (<body-region>, <block-region-mixin>, <queueable-mixin>, <annotatable>)
end;

// A <function-region>'s Parent slot is the <component>, but
// conceptually it can have multiple parent regions (call sites).  The
// phi function joins the values coming from the different callers.
// The exits to a <function-region> must all be <return>s, and in fact
// indicate the return values.
//
define class <function-region> (<block-region>)
end;

// A <loop-region> repeats execution of the body indefinitely (terminate by
// exit to an outer block.)  The phi function is at the head of the loop,
// joining values coming from the outside with values from previous iterations.
//
define class <loop-region> (<body-region>)
end;


// An <exit> represents a control transfer out of the current construct and
// back up to the end of some enclosing <block-region>.  It doesn't contain any
// code.
// 
define class <exit> (<region>)
  slot block-of :: <block-region-mixin>, required-init-keyword: block:;
  slot next-exit :: false-or(<exit>), required-init-keyword: next:;
end;


// A <return> is a special kind of exit that passes values.
// 
define class <return> (<exit>, <dependent-mixin>)
  slot returned-type :: <values-ctype>, init-function: wild-ctype;
end;

// Represents all the stuff we're currently compiling.  This is also a
// pseudo-block, in that it can have exits to it (representing expressions that
// unwind.)
//
define class <component> (<block-region-mixin>)
  keyword source-location:, init-value: make(<source-location>);
  //
  // Queue of all the <initial-definition> variables that need to be ssa
  // converted (threaded through next-initial-definition).
  slot initial-definitions :: false-or(<initial-definition>),
    init-value: #f;
  //
  // Queue of things that need to be updated (threaded by queue-next.)
  slot reoptimize-queue :: false-or(<queueable-mixin>), init-value: #f;
  //
  // List of all the <function-regions>s in this component.
  slot all-function-regions :: <stretchy-vector>,
    init-function: curry(make, <stretchy-vector>);
end;

define method add-to-queue
    (component :: <component>, queueable :: <queueable-mixin>) => ();
  queueable.queue-next := component.reoptimize-queue;
  component.reoptimize-queue := queueable;
end;

