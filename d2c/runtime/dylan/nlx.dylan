rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/runtime/dylan/nlx.dylan,v 1.3 1995/11/13 23:09:07 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.
module: dylan-viscera

define abstract class <unwind-block> (<object>)
  slot saved-stack :: <raw-pointer>,
    required-init-keyword: saved-stack:;
  slot saved-uwp :: false-or(<unwind-protect>),
    required-init-keyword: saved-uwp:;
  slot saved-handler :: false-or(<handler>),
    required-init-keyword: saved-handler:;
end;

define class <unwind-protect> (<unwind-block>)
  slot cleanup :: <function>,
    required-init-keyword: cleanup:;
end;

seal generic make (singleton(<unwind-protect>));
seal generic initialize (<unwind-protect>);

define method push-unwind-protect (cleanup :: <function>) => ();
  let thread = this-thread();
  thread.cur-uwp := make(<unwind-protect>,
			 saved-stack: %%primitive current-sp(),
			 saved-uwp: thread.cur-uwp,
			 saved-handler: thread.cur-handler,
			 cleanup: cleanup);
end;

define method pop-unwind-protect () => ();
  let thread = this-thread();
  thread.cur-uwp := thread.cur-uwp.saved-uwp;
end;

define class <catcher> (<unwind-block>)
  slot saved-state :: <raw-pointer>, required-init-keyword: saved-state:;
  slot disabled :: <boolean>, init-value: #f;
  slot thread :: <thread>, required-init-keyword: thread:;
end;

seal generic make (singleton(<catcher>));
seal generic initialize (<catcher>);

define method make-catcher (saved-state :: <raw-pointer>) => res :: <catcher>;
  let thread = this-thread();
  make(<catcher>,
       saved-stack: %%primitive current-sp(),
       saved-uwp: thread.cur-uwp,
       saved-handler: thread.cur-handler,
       saved-state: saved-state,
       thread: thread);
end;

define method make-exit-function (catcher :: <catcher>) => res :: <function>;
  method (#rest args)
    throw(catcher, args);
  end;
end;

define method disable-catcher (catcher :: <catcher>) => ();
  catcher.disabled := #t;
end;


define constant catch
  = method (saved-state :: <raw-pointer>, thunk :: <function>)
      thunk(saved-state);
    end;

define method throw (catcher :: <catcher>, values :: <simple-object-vector>)
    => res :: type-or();
  if (catcher.disabled)
    error("Can't exit to a block that has already been exited from.");
  end;
  let this-thread = this-thread();
  unless (catcher.thread == this-thread)
    error("Can't exit from a block set up by some other thread.");
  end;
  let target-uwp = catcher.saved-uwp;
  let uwp = this-thread.cur-uwp;
  until (uwp == target-uwp)
    %%primitive unwind-stack(uwp.saved-stack);
    let prev = uwp.saved-uwp;
    this-thread.cur-uwp := prev;
    this-thread.cur-handler := uwp.saved-handler;
    uwp.cleanup();
    uwp := prev;
  end;
  catcher.disabled := #t;
  %%primitive unwind-stack(catcher.saved-stack);
  this-thread.cur-handler := catcher.saved-handler;
  // Note: the values-sequence has to happen after the unwind-stack.
  %%primitive throw(catcher.saved-state, values-sequence(values));
end;
