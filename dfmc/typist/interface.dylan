module: dfmc-typist

//the external entry (sometimes also internal entry)
// there are some cases:
//  - type is in type graph, which has to be solved and type returned
//  - inlined temporary, type is in generator.computation-type
//  - inlined object-reference, type estimated and cached via lookup-type-node?!
//if an inlined data flow node receives a new type, this will occur in type graph,
//thus the first case is always the most current estimate

define function type-estimate (c :: <computation>, o :: <object>)
 => (te :: type-union(<collection>, <&type>))
  block()
    let context = c.type-environment;
    if (in-type-environment?(context, o))
      solve(context);
      let node = element(context, o, default: #f);
      node.node-to-model-type
    elseif (instance?(o, <temporary>) & o.generator & o.generator.computation-type)
      o.generator.computation-type
    else
      o.type-estimate-object
    end;
  exception (e :: <condition>)
    dynamic-bind(*typist-visualize* = #f)
      o.type-estimate-object
    end;
  end;
end;

define function retract-type! (c :: <computation>) => ()
  let context = c.type-environment;
  c.computation-type := #f;
  c.item-type-status? := #t;
  let t = c.temporary;
  local method rec-rem (te :: <type-environment>)
          let n = element(te.real-environment, t, default: #F);
          if (n) remove-node(n) end;
          remove-key!(te.real-environment, t);
          for (type-env in te.inner-type-environments)
            rec-rem(type-env)
          end;
        end;
  rec-rem(context);
end;

define compiler-sideways method re-optimize-type-estimate (c :: <computation>) => ()
  c.item-type-status? := #t;
end;

define method re-type (c :: <computation>) => ()
  dynamic-bind(*upgrade?* = #f)
    infer-computation-types(c);
  end
end method;

//define method re-type (c :: <make-cell>) => ()
//  next-method();
//  maybe-upgrade-cell(c.temporary);
//end;

//define method re-type (c :: <set-cell-value!>) => ()
//  next-method();
//  maybe-upgrade-cell(c.computation-cell);
//end;

define method re-type (c :: <loop>) => ()
end method;

define function upgrade-cells (l :: <&lambda>) => (res :: <boolean>)
  let done? = #f;
  for (e in l.environment.temporaries)
    if (instance?(e, <cell>))
      done? := maybe-upgrade-cell(e) | done?
    end;
  end;
  done?
end;

define function maybe-upgrade-cell (c :: <cell>) => (res :: <boolean>)
  if (c.finished-conversion?)
    let gens = pair(c.generator, choose(rcurry(instance?, <set-cell-value!>), c.users));
    if (every?(type-environment, gens))
      let cell-t = apply(^type-union, map(method(x) type-estimate(x, x.computation-value) end, gens));
      //the next two bindings are there because of raw-types not being subtypes of <object>
      let cell-t-comparator = if (cell-t == dylan-value(#"<object>"))
                                make(<&top-type>)
                              else
                                cell-t
                              end;
      let old-cell-t-comparator = if (c.cell-type == dylan-value(#"<object>"))
                                    make(<&top-type>)
                                  else
                                    c.cell-type
                                  end;
      if (instance?(cell-t, <&top-type>))
        cell-t := dylan-value(#"<object>") //XXX: this should go away!
      end;
      if (^subtype?(cell-t-comparator.cell-representation, old-cell-t-comparator.cell-representation))
        unless (^subtype?(old-cell-t-comparator.cell-representation, cell-t-comparator.cell-representation))
          c.cell-type := cell-t;
          //now, safety ahead: there might be assignment-check-type generated which check for the
          //old type, update them!
          let box-t = make-object-reference(cell-t);
          for (u in gens)
            if (instance?(u.computation-value, <temporary>) & u.computation-value.generator)
              if (instance?(u.computation-value.generator, <assignment-check-type>))
                remove-user!(u.computation-value.generator.type, u.computation-value.generator);
                u.computation-value.generator.type := box-t;
                add-user!(box-t, u.computation-value.generator);
              end;
            end;
          end;
          //ok, this might lead to recursion, where not all users of the cell have been updated
          //yet, thus providing a broader type
          c.finished-conversion? := #f;
          re-optimize-users(c);
          re-optimize(c.generator);
          c.finished-conversion? := #t;
          #t
        end;
      else
        //error("this shouldn't happen! (cell-type %= new-type %=)", c.cell-type, cell-t);
      end
    end;
  end;
end;

//define compiler-sideways method re-optimize-type-estimate (c :: <merge>) => ()
//  infer-computation-types(c);
//end;

define thread variable *upgrade?* :: <boolean> = #t;

define compiler-sideways method re-type-computations
    (env :: <type-environment>, first :: false-or(<computation>), last :: false-or(<computation>)) => ()
  if (first) //env.finished-initial-typing? & first)
    type-walk(env, first, last.next-computation, infer?: #f);
    walk-computations(re-type, first, last.next-computation);
    //walk-computations(re-type, first, last.next-computation);
  end;
end;

define function initialize-type-environment!
 (env :: <type-environment>, first :: false-or(<computation>), last :: false-or(<computation>)) => ()
  type-walk(env, first, #f, infer?: #f);
  walk-computations(method(x)
//                      if (x.computation-type)
//                        x.item-type-status? := #f
//                      else
                        x.re-type
//                      end
                    end, first, #f);
end;
define constant guaranteed-disjoint? = ^known-disjoint?;
