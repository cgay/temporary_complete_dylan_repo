module: assembler


define macro brain-definer
  { define brain ?:name ?states end }
    => { define function ?name() => brain :: <vector>;
           let instrs = make(<table>);
           let (label, counter) = values(start:, 0);
           ?states;
           compile-states(instrs)
         end function }

states:
  { } => { }
  { [?label:expression] ?state; ... }
    => { let (label, counter) = values(?label, 0); ?state; ... }
  { ?state; ... }
    => { let counter = counter + 1; ?state; ... }

 state:
  { Verbatim { ?:expression } }
    => { push-thunk(instrs, label, counter,
                    method()
                        ?expression
                    end) }

  { Drop, (?label:name) }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<drop>, state: curry(lookup, instrs, ?#"label", 0))
                    end) }

  { Drop }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<drop>, state: curry(lookup, instrs, label, counter + 1))
                    end) }

  { Mark ?:expression, (?label:name) }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<mark>,
                             marker: ?expression,
                             state: curry(lookup, instrs, ?#"label", 0))
                    end) }

  { Mark ?:expression }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<mark>,
                             marker: ?expression,
                             state: curry(lookup, instrs, label, counter + 1))
                    end) }


  { Unmark ?:expression, (?label:name) }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<unmark>,
                             marker: ?expression,
                             state: curry(lookup, instrs, ?#"label", 0))
                    end) }

  { Unmark ?:expression }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<unmark>,
                             marker: ?expression,
                             state: curry(lookup, instrs, label, counter + 1))
                    end) }




  { Turn ?:name, (?label:name) }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<turn>,
                             left-or-right: ?#"name",
                             state: curry(lookup, instrs, ?#"label", 0))
                    end) }

  { Turn ?:name }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<turn>,
                             left-or-right: ?#"name",
                             state: curry(lookup, instrs, label, counter + 1))
                    end) }


  { PickUp ?success:name => ?fail:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<pickup>,
                                  state-success:
                                    curry(lookup, instrs, ?#"success", 0),
                                  state-failure:
                                    curry(lookup, instrs, ?#"fail", 0))
                    end) }

  { PickUp => ?:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<pickup>,
                                  state-success:
                                    curry(lookup, instrs, label, counter + 1),
                                  state-failure:
                                    curry(lookup, instrs, ?#"name", 0))
                    end) }


  { Move ?success:name => ?fail:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<move>,
                                  state-success:
                                    curry(lookup, instrs, ?#"success", 0),
                                  state-failure:
                                    curry(lookup, instrs, ?#"fail", 0))
                    end) }

  { Move => ?:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<move>,
                                  state-success:
                                    curry(lookup, instrs, label, counter + 1),
                                  state-failure:
                                    curry(lookup, instrs, ?#"name", 0))
                    end) }

  { Flip ?prob:expression, (?yes:name, ?no:name) }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<flip>,
                             probability: ?prob,
                             state-success: curry(lookup, instrs, ?#"yes", 0),
                             state-failure: curry(lookup, instrs, ?#"no", 0))
                    end method) }

  { Flip ?prob:expression, (?yes:name) }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<flip>,
                             probability: ?prob,
                             state-success: curry(lookup, instrs, ?#"yes", 0),
                             state-failure: curry(lookup, instrs, label, counter + 1))
                    end method) }

  { Flip ?prob:expression => ?no:name }
    => { push-thunk(instrs, label, counter,
                    method()
                        make(<flip>,
                             probability: ?prob,
                             state-success: curry(lookup, instrs, label, counter + 1),
                             state-failure: curry(lookup, instrs, ?#"no", 0))
                    end method) }

  { Sense ?where:name (Marker ?what:expression) => ?no:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: ?#"where",
                                  condition: as(<symbol>, format-to-string("marker%d", ?what)),
                                  state-true: curry(lookup, label, counter + 1),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }

  { Sense (Marker ?what:expression) => ?no:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: #"Here",
                                  condition: as(<symbol>, format-to-string("marker%d", ?what)),
                                  state-true: curry(lookup, instrs, label, counter + 1),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }
  { Sense ?where:name ?what:name => ?no:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: ?#"where",
                                  condition: ?#"what",
                                  state-true: curry(lookup, instrs, label, counter + 1),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }

  { Sense ?what:name => ?no:name }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: #"Here",
                                  condition: ?#"what",
                                  state-true: curry(lookup, instrs, label, counter + 1),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }


  { Sense ?where:name (Marker ?what:expression), (?yes:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: ?#"where",
                                  condition: as(<symbol>, format-to-string("marker%d", ?what)),
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, label, counter + 1))
                    end) }

  { Sense (Marker ?what:expression), (?yes:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: #"Here",
                                  condition: as(<symbol>, format-to-string("marker%d", ?what)),
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, label, counter + 1))
                    end) }
  { Sense ?where:name ?what:name, (?yes:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: ?#"where",
                                  condition: ?#"what",
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, label, counter + 1))
                    end) }

  { Sense ?what:name, (?yes:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: #"Here",
                                  condition: ?#"what",
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, label, counter + 1))
                    end) }

  { Sense ?where:name (Marker ?what:expression), (?yes:name, ?no:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: ?#"where",
                                  condition: as(<symbol>, format-to-string("marker%d", ?what)),
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }

  { Sense (Marker ?what:expression), (?yes:name, ?no:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: #"Here",
                                  condition: as(<symbol>, format-to-string("marker%d", ?what)),
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }
  { Sense ?where:name ?what:name, (?yes:name, ?no:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: ?#"where",
                                  condition: ?#"what",
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }

  { Sense ?what:name, (?yes:name, ?no:name) }
    => { push-thunk(instrs, label, counter,
                    method() make(<sense>,
                                  direction: #"Here",
                                  condition: ?#"what",
                                  state-true: curry(lookup, instrs, ?#"yes", 0),
                                  state-false: curry(lookup, instrs, ?#"no", 0))
                    end) }
end macro;


define function push-thunk (instrs, label, counter, thunk) => ();
///////  let pos = make(<instruction-label-count>, label: label, count: counter);
  let pos = as(<symbol>, format-to-string("(%s, %d)", label, counter));
  if (element(instrs, pos, default: #f))
    error("label %s already defined?", label);
  end;
  
  instrs[pos] := thunk;
end;

define function lookup (instrs, label, counter)
 => instr :: <instruction>;
////////  let pos = make(<instruction-label-count>, label: label, count: counter);

  let pos = as(<symbol>, format-to-string("(%s, %d)", label, counter));
  
  block ()
    let instr = instrs[pos];
    select (instr by instance?)
      <function> =>
        instrs[pos] := instr();
      otherwise =>
        instr;
    end;
  exception (<error>)
    format-out("lookup: (%s, %d), did you fall off your block?\n", label, counter);
  end block;
end;

define function compile-states (instrs :: <table>)
 => brain :: <vector>;
  let brain :: <stretchy-vector> = make(<stretchy-vector>);
  let start-instr = lookup(instrs, start:, 0);
  let pos-table :: <table> = make(<table>);
  put-instruction(start-instr, brain, pos-table);
  brain;
end;

define generic put-instruction(instr :: <instruction>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();

define method put-instruction(instr :: <instruction>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  unless (element(pos-table, instr, default: #f))
    pos-table[instr] := brain.size;
    add!(brain, instr);
  end
end;

define macro integrate-state
  { integrate-state(?state:name, ?instr:expression, ?brain:expression, ?pos-table:expression) }
  =>
  {
    let next-state = ?instr.?state;
    select (next-state by instance?)
      <function> =>
          ?instr.?state := next-state();
          put-instruction(?instr, ?brain, ?pos-table);
      <instruction> =>
        let pos = element(?pos-table, next-state, default: #f);
        if (pos)
          ?instr.?state := pos;
        else
          put-instruction(next-state, ?brain, ?pos-table);
          put-instruction(?instr, ?brain, ?pos-table);
        end;
      <integer> =>
        #t // we are done
    end select;
  }
end;

define method put-instruction(instr :: <sense>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state-true, instr, brain, pos-table);
  integrate-state(state-false, instr, brain, pos-table);
end;
  
define method put-instruction(instr :: <mark>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state, instr, brain, pos-table);
end;
  
define method put-instruction(instr :: <unmark>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state, instr, brain, pos-table);
end;
  
define method put-instruction(instr :: <pickup>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state-success, instr, brain, pos-table);
  integrate-state(state-failure, instr, brain, pos-table);
end;
  

define method put-instruction(instr :: <drop>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state, instr, brain, pos-table);
end;

define method put-instruction(instr :: <turn>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state, instr, brain, pos-table);
end;
  
define method put-instruction(instr :: <move>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state-success, instr, brain, pos-table);
  integrate-state(state-failure, instr, brain, pos-table);
end;

define method put-instruction(instr :: <flip>, brain :: <stretchy-vector>, pos-table :: <table>)
 => ();
  next-method();
  integrate-state(state-success, instr, brain, pos-table);
  integrate-state(state-failure, instr, brain, pos-table);
end;
  

define function dump-brain(brain :: <vector>)
  map(compose(curry(format-out, "%s\n"), unparse), brain)
end;

define functional class <instruction-label-count> (<object>)
  constant slot instruction-label, required-init-keyword: label:;
  constant slot instruction-count, required-init-keyword: count:;
end;

define sealed domain make(singleton(<instruction-label-count>));
define sealed domain initialize(<instruction-label-count>);

define method functional-==
    (c == <instruction-label-count>, l :: <instruction-label-count>, r :: <instruction-label-count>)
 => (same :: <boolean>);
/// format-out("functional-==: (%s, %d) ==? (%s, %d)\n", l.instruction-label, l.instruction-count, r.instruction-label, r.instruction-count);
  l.instruction-label == r.instruction-label
    & l.instruction-count == r.instruction-count
end;


// direct builders
// intended for use with "Verbatim"

define function Drop(next-state :: <instruction>)
 => instruction :: <drop>;
  make(<drop>, state: next-state)
end;


