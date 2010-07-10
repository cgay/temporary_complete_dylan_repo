Module: dylan-user
Author: Jonathan Bachrach and Keith Playford
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library dfmc-flow-graph
  use functional-dylan;
  use dfmc-common;
  use dfmc-definitions;
  use dfmc-modeling;
  use dfmc-namespace;
  use dfmc-reader;
  export dfmc-flow-graph;
end library;

define module dfmc-flow-graph
  use functional-dylan;
  use transcendentals;
  use dfmc-common;
  use dfmc-definitions;
  use dfmc-imports;
  use dfmc-namespace;
  use dfmc-modeling,
    export: 
      {frame-size,
       name, name-setter, 
       body, body-setter,
       environment, environment-setter,
       function, function-setter};
  use dfmc-reader;

  export
    ensure-invariants,
    <closure-entry-strength>,
    $no-closure-entry,
    $weak-closure-entry,
    $strong-closure-entry,
    do-over-lambda-users,
    analyze-environments;
  
  export // computations
    <computation>,
    previous-computation, previous-computation-setter,
    temporary, temporary-setter,
    computation-value, computation-value-setter,
    // *** environment, environment-setter,
    computation-type, computation-type-setter,
    %label, %label-setter,
    next-computation, next-computation-setter,
    make-in-environment,
    make-with-temporary,
    used-temporary-accessors,
    <temporary-accessors>,
      temporary-getter,
      temporary-zetter,
    class-used-temporary-accessors,
    walk-lambda-computations, walk-computations,
    walk-all-lambda-computations,
    walk-computation-references,
    walk-lambda-references, walk-all-lambda-references,
    *computation-tracer*, computation-id, temporary-id,
    %computation-id,
    
    <nop-computation>,
    <nop>,
    <value-reference>,
    <binding-reference>,
      referenced-binding,
    <module-binding-reference>,
    <variable-reference>,
    <defined-constant-reference>,
    <interactor-binding-reference>,
    <object-reference>,
      reference-value, reference-value-setter,
    <immutable-object-reference>,
    <method-reference>,
    <make-closure>,
      lambda-make-closure,
      computation-closure-method, computation-closure-method-setter,
      computation-init-closure, computation-init-closure-setter, 
      computation-init-closure?, 
      method-top-level?,
      computation-top-level-closure?,
      computation-signature-value, computation-signature-value-setter,
      computation-no-free-references?, computation-no-free-references?-setter,
      closure-has-dynamic-extent?, closure-has-dynamic-extent?-setter,
    <initialize-closure>,
      computation-closure, computation-closure-setter,
    <assignment>, 
      assigned-binding,
    <set!>,
    <any-definition>,
      <definition>,
      <redefinition>,
    <type-reference>,
    <any-type-definition>,
      typed-binding,
      <type-definition>,
      <type-redefinition>,
    <conditional-update!>,
      computation-test-value,
    <temporary-transfer-computation>,
    <temporary-transfer>,
    <keyword-default>,
      keyword-default-value-keyword-variable,
      keyword-default-value-specifiers,
      keyword-default-value-index,
    <merge>,
    <binary-merge>,
      merge-left-value, merge-right-value,
      merge-left-value-setter, merge-right-value-setter,
      merge-left-previous-computation, 
      merge-right-previous-computation,
      merge-left-previous-computation-setter, 
      merge-right-previous-computation-setter,
    <if-merge>,
    <loop-merge>,
      loop-merge-loop,      loop-merge-loop-setter,
      loop-merge-call,      loop-merge-call-setter,
      loop-merge-parameter, loop-merge-parameter-setter,
      loop-merge-argument,  loop-merge-argument-setter,
      loop-merge-initial?,  loop-merge-initial?-setter,
    <bind-exit-merge>,
    <any-slot-value>, 
    <slot-value>,
      computation-instance, computation-instance-setter,
      computation-guaranteed-initialized?,
      computation-slot-descriptor, computation-slot-descriptor-setter,
      computation-slot-offset, computation-slot-offset-setter,
    <slot-value-setter>,
      computation-new-value, computation-new-value-setter,
    <any-repeated-slot-value>, 
      computation-index-tagged?, computation-index-tagged?-setter,
    <repeated-slot-value>,
      computation-repeated-byte?,
      computation-index, computation-index-setter,
    <repeated-slot-value-setter>,
    <call>,
    arguments, arguments-setter,
    compatibility-state, compatibility-state-setter,
      $compatibility-unchecked,
      $compatibility-checked-compatible,
      $compatibility-checked-incompatible,
    dispatch-state, dispatch-state-setter,
      $dispatch-untried,
      $dispatch-tried,
    call-iep?, call-iep?-setter,
    call-congruent?, call-congruent?-setter,
    <stack-vector>,
    <function-call>,
    // *** function, function-setter,
    <primitive-call>,
    primitive, primitive-setter,
    <primitive-indirect-call>,
    <c-variable-pointer-call>,
      c-variable, c-variable-setter,
    <begin-with-stack-structure>,
      end-wss, end-wss-setter,
      wss-size-temp, wss-size-temp-setter,
      wss-var, wss-var-setter,
    <end-with-stack-structure>,
      begin-wss, begin-wss-setter,
    <simple-call>,
      call-inlining-depth, call-inlining-depth-setter, 
    <method-call>,
      next-methods, next-methods-setter,
    <engine-node-call>,
      engine-node,
    <apply>,
    <method-apply>,
      // next-methods, next-methods-setter,
    <engine-node-apply>,
    <if>,
    test, test-setter,
    consequent, consequent-setter,
    alternative, alternative-setter,
    <loop>,
      loop-parameters,
      loop-merges, loop-merges-setter,
      loop-body, loop-body-setter,
    <end-loop>,
      ending-loop,
    <loop-call>,
      loop-call-loop,
      loop-call-arguments,
      loop-call-merges, loop-call-merges-setter,
    <block>,
    entry-state, entry-state-setter,
    // *** body, body-setter,
    <bind-exit>,
    <unwind-protect>,
    protected-temporary, 
    protected-end, protected-end-setter,
    cleanups, cleanups-setter,
    cleanups-end, cleanups-end-setter,
    has-body?, has-cleanups?,
   <end>,
    <end-block>,
    <return>,
    <end-exit-block>,
    <end-protected-block>,
    return-temp, return-temp-setter,
    <end-cleanup-block>,
    <exit>,
    <bind>,
      bind-return, bind-return-setter,
    <values>,
    fixed-values, fixed-values-setter,
    rest-value, rest-value-setter,
    <extract-value-computation>,
    <extract-single-value>,
    extract-value-index-guaranteed?, extract-value-index-guaranteed?-setter,
    <extract-rest-value>,
    index, index-setter,
    <multiple-value-spill>,
    <multiple-value-unspill>,
    <adjust-multiple-values-computation>,
    $max-number-values-field-size,
    $max-number-values,
    <adjust-multiple-values>,
    <adjust-multiple-values-rest>,
    number-of-required-values,
    
    \for-lambda,
    \for-used-lambda, do-used-lambdas, lambda-used?, lambda-users,
    \for-all-lambdas, do-all-lambdas, 
    \for-all-used-lambdas, 
    \for-computations,
    do-used-value-references,

    <check-type-computation>,
    <assignment-check-type>,
      lhs-variable-name,
    <single-value-check-type-computation>,
    <check-type>,
    <keyword-check-type>,
    <constrain-type>,
    <multiple-value-check-type-computation>,
    <multiple-value-check-type>,
    <multiple-value-check-type-rest>,
    <result-check-type-computation>,
    <single-value-result-check-type>,
    <multiple-value-result-check-type>,
    <multiple-value-result-check-type-rest>,
    type, type-setter,
    types,
    rest-type, rest-type-setter,
    <guarantee-type>,
    guaranteed-type, guaranteed-type-setter,
    static-guaranteed-type, static-guaranteed-type-setter,

    <make-cell>,
    <get-cell-value>,
    <set-cell-value!>,
    computation-cell, computation-cell-setter,
    %cell-type,

    computation-source-location, computation-source-location-setter,
    dfm-source-location,
    dfm-context-id,
    \with-parent-computation, do-with-parent-computation;

  export // environments and variables
    <lexical-variable>,
    <lexical-specialized-variable>,
    <lexical-required-variable>,
    specializer, specializer-setter,
    <lexical-local-variable>,
    <lexical-optional-variable>,
    <lexical-rest-variable>,
    <lexical-keyword-variable>,
    // *** frame-size, 
    frame-size-setter,
    <lexical-environment>,
    $top-level-environment,
    top-level-environment?,
    <lambda-lexical-environment>,
      strip-bindings,
      strip-assignments,
      strip-environment,
    <local-lexical-environment>,
    make-local-lexical-environment,
    outer, outer-setter,
    inners, inners-setter,
    lambda, lambda-setter,
    closure, closure-setter,
    entries, entries-setter,
    loops, loops-setter,
    lambda-loop, lambda-loop-setter,
    temporaries, temporaries-setter,
    \for-temporary,
    add-temporary!, remove-temporary!,
    clear-temporaries!,	 
    ensure-lambda-body,
    add-inner!,
    extract-lambda,
    lambda-has-free-lexical-references?,
    closure-self-reference?,
    closure-self-referencing?,
    all-environments,
    next-frame-offset,
    add-variable!,
    lambda-environment,
    lookup,
    inner-environment?;
    
  export // temporaries
    <temporary>,
    <named-temporary-mixin>,
    <named-temporary>,
    frame-offset, frame-offset-setter,
    generator, generator-setter,
    // *** environment, environment-setter,
    assignments, assignments-setter,
    closed-over?, closed-over?-setter,
    dynamic-extent?, dynamic-extent?-setter,

    <cell>,
      cell-type, cell-type-setter,
    cell?,

    <stack-vector-temporary>,
    number-values, number-values-setter,

    <multiple-value-temporary>,
    required-values, required-values-setter,
    rest-values?, rest-values?-setter,
    mvt-required-initialized?,
    multiple-values?,
    mvt-transfer-values!,

    <entry-state>,
    // *** name, name-setter,
    me-block, me-block-setter,
    exits, exits-setter,
    local-entry-state?, local-entry-state?-setter;

  export // utilities
    lambda-has-free-lexical-references?,
    final-computation,
    join!, 
    join-1x1!, join-1x1-t!, 
    join-2x1!, join-2x1-t!, 
    join-2x2!, join-2x2-t!,
    redirect-previous-computations!,
    redirect-next-computations!,
    insert-computation-after!,
    insert-computation-before!,
    insert-computation-before-reference!,
    insert-computations-before-reference!,
    delete-computation!,
    insert-computations-after!,
    insert-computations-before!,
    remove-computation-references!,
    remove-computation-block-references!,
    delete-computation-block!,
    maybe-delete-function-body,
    replace-computation!,
    replace-computation-with-temporary!,
    replace-temporary-references!,
    rename-temporary!,
    rename-temporary-references!,
    replace-temporary-in-users!,
    redirect-next-computations!, redirect-next-computation!,
    redirect-previous-computations!, redirect-previous-computation!;

  export // queue
    <queueable-item-mixin>,
      item-status, item-status-setter,

    $queueable-item-absent,
    $queueable-item-present,
    $queueable-item-dead,

    add-to-queue!,
    queue-head,
    queue-pop, 
    reverse-queue!,
    add-to-queue!,
    print-queue-out,
    do-queue,

    <optimization-queue>,
    init-optimization-queue,
    re-optimize,
    re-optimize-into,
    re-optimize-into!,
    re-optimize-type-estimate,
    re-optimize-users,
    re-optimize-local-users,
    re-optimize-generators;

  export
    <dfm-copier>,
    $max-inlining-depth,
    \with-dfm-copier-environment,
    *dfm-copier-environment-context*,
    *inlining-depth*,
    number-temporaries,
    estimated-copier-table-size,
    current-dfm-copier;
end module;
