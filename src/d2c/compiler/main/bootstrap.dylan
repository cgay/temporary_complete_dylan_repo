module: dylan
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/main/bootstrap.dylan,v 1.22 1995/05/26 10:46:16 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

// Have to use the define %%module internal form because define module
// hasn't been defined yet.
//
define %%module dylan
end;


// Statement macros.

define macro begin
    { begin ?body end } => { %%begin ?body end };
end;

define macro block
    { block () ?body end } => { begin ?body end }
    { block (?name) ?body end } => { %%bind-exit (?name) ?body end }
    { block () ?body cleanup ?body:cleanup end }
      => { %%unwind-protect ?body %%cleanup ?cleanup end }
    { block (?name) ?body cleanup ?body:cleanup end }
      => { %%bind-exit (?name)
	     %%unwind-protect ?body %%cleanup ?cleanup end
	   end }
    { block () ?bbody end }
      => { %%bind-exit (done)
	     %%bind-exit (do-handler)
	       %%mv-call(done, begin ?bbody end);
	     end();
	   end }
    { block (?name) ?bbody end }
      => { %%bind-exit (done)
	     let ?name = done;
	     %%bind-exit(do-handler)
	       %%mv-call(done, begin ?bbody end);
	     end();
	   end }
  bbody:
    { ... cleanup ?body }
      => { %%unwind-protect
	     %%bind-exit (do-handler)
	       %%mv-call(done, begin ... end);
	     end();
	   %%cleanup
	     ?body
	   end }
    { ... exception ?name ?body }
      => { let handler ?name
	     = method (condition, next-handler)
		 do-handler(method () ?body end);
	       end;
	    ... }
    { ... exception (?expr, #rest ?opt, #key ?test (#f), ?init-arguments (#f))
	    ?body }
      => { let handler (?expr, ?opt)
	     = method (condition, next-handler)
		 do-handler(method () ?body end);
	       end;
	    ... }
    { ... exception (?name :: ?expr, #rest ?opt, 
		     #key ?test (#f), ?init-arguments (#f))
	    ?body }
      => { let handler (?expr, ?opt)
	     = method (?name, next-handler)
		 do-handler(method () ?body end);
	       end;
	    ... }
    { ?body } => { ?body };
end;

define macro case
    { case ?case-body end } => { ?case-body }
  case-body:
    { ?expr => ; ... }
      => { begin let temp = ?expr; if (temp) temp else ... end end }
    { ?expr => ?body ; ... } => { if (?expr) ?body else ... end }
    { otherwise ?body } => { ?body }
    { } => { #f }
end;

define macro for
    { for (?header) ?fbody end } => { %%for (?header) ?fbody end }
  fbody:
    { ?body } => { ?body %%finally }
    { ?body:b1 finally ?body:b2 } => { ?b1 %%finally ?b2 }
  header:
    { ?var in ?expr, ... } => { %%in ?var, ?expr; ... }
    { ?var = ?expr:e1 then ?expr:e2, ... } => { = ?var, ?e1, ?e2; ... }
    { ?var from ?expr ?to, ... } => { %%from ?var, ?expr, ?to; ... }
    { #key ?while } => { %%while ?while }
    { #key ?until } => { %%while ~ ?until }
    { } => { }
  to:
    { to ?expr ?by } => { ?by, to ?expr }
    { above ?expr ?by } => { ?by, above ?expr }
    { below ?expr ?by } => { ?by, below ?expr }
    { ?by } => { ?by }
  by:
    { by ?expr } => { ?expr }
    { } => { 1 }
end;

define macro if
    { if (?expr) ?body ?elses end }
      => { %%if (?expr) ?body ?elses end }
  elses:
    { else ?body } => { %%else ?body };
    { elseif (?expr) ?body ... } => { %%else %%if (?expr) ?body ... end };
    { } => { %%else #f };
end;

define macro method
    { method ?noise end } => { %%method ?noise end }
end;

define macro select
    { select (?what) ?case-body end }
      => { ?what; ?case-body }
  what:
    { ?expr by ?expr:fn } => { let target = ?expr; let fn = ?fn }
    { ?expr } => { let target = ?expr; let fn = \== }
  case-body:
    { } => { error("select error") }
    { otherwise ?body } => { ?body }
    { ?keys => ?body ; ... } => { if (?keys) ?body else ... end }
  keys:
    { ?expr } => { fn(target, ?expr) }
    { ?expr , ... } => { fn(target, ?expr) | ... }
end;

define macro unless
    { unless (?expr) ?body end } => { %%if (?expr) #f %%else ?body end }
end;

define macro until
    { until (?expr) ?body end }
      => { begin
	     local method loop () 
		     unless (?expr)
		       begin ?body end;
		       loop();
		     end;
		   end;
	     loop();
	   end }
end;

define macro while
    { while (?expr) ?body end }
      => { begin
	     local method loop () 
		     if (?expr)
		       begin ?body end;
		       loop();
		     end;
		   end;
	     loop();
	   end }
end;


// Function macros.

define macro \&
    { \& (?exprs) } => { ?exprs }
  exprs:
    { } => { #t }
    { ?expr } => { ?expr }
    { ?expr , ... } => { if (?expr) ... end }
end;

define macro \|
    { \| (?exprs) } => { begin ?exprs end }
  exprs:
    { } => { #f }
    { ?expr } => { ?expr }
    { ?expr, ... } => { let temp = ?expr; if (temp) temp else ... end }
end;

define macro \:=
    { \:= (?expr:place, ?expr:value) } => { %%set (?place, ?value) }
end;


// Define macros

define macro class-definer
    { define ?modifiers class ?name (?supers) ?slots end }
      => { define ?modifiers %%class ?name (?supers) ?slots end }
  modifiers:
    { } => { }
    { open ... } => { open ... }
    { sealed ... } => { sealed ... }
    { free ... } => { free ... }
    { primary ... } => { primary ... }
    { abstract ... } => { abstract ... }
    { concrete ... } => { concrete ... }
    { functional ... } => { functional ... }
  supers:
    { ?expr } => { ?expr }
    { ?expr, ... } => { ?expr, ... }
  slots:
    { } => { }
    { inherited slot ?name, #rest ?options; ... }
      => { inherited ?name, ?options; ... }
    { required keyword ?key, #rest ?options; ... }
      => { keyword ?key, required: #t, ?options; ... }
    { keyword ?key, #rest ?options; ... }
      => { keyword ?key, ?options; ... }
    { ?slot-modifiers slot ?name, #rest ?options; ... }
      => { slot ?name, ?slot-modifiers, ?options; ... }
    { ?slot-modifiers slot ?name :: ?type, #rest ?options; ... }
      => { slot ?name, type: ?type, ?slot-modifiers, ?options; ... }
  slot-modifiers:
    { } => { }
    { instance } => { allocation: #"instance" }
    { class } => { allocation: #"class" }
    { each-subclass } => { allocation: #"each-subclass" }
    { constant } => { allocation: #"constant" }
    { virtual } => { allocation: #"virtual" }
    { open ... } => { open: #t, ... }
    { sealed ... } => { sealed: #t, ...}
end;

define macro constant-definer
    { define constant ?bindings } => { define %%constant ?bindings }
end;

define macro library-definer
    { define library ?name ?clauses end }
      => { define %%library ?name ?clauses end }
  clauses:
    { use ?name, #key ?import (all), ?exclude ({}), ?prefix (#f),
		      ?rename ({}), ?export ({}); ... }
      => { %%use ?name, ?import, ?exclude, ?prefix, ?rename, ?export; ... }
    { export ?names ; ... }
      => { %%export ?names; ... }
    { } => { }
  names:
    { ?name } => { ?name }
    { ?name, ... } => { ?name, ... }
end;

define macro module-definer
    { define module ?name ?clauses end }
      => { define %%module ?name ?clauses end }
  clauses:
    { use ?name, #key ?import (all), ?exclude ({}), ?prefix (#f),
		      ?rename ({}), ?export ({}); ... }
      => { %%use ?name, ?import, ?exclude, ?prefix, ?rename, ?export; ... }
    { export ?names ; ... }
      => { %%export ?names; ... }
    { create ?names ; ... }
      => { %%export ?names; ... }
    { } => { }
  names:
    { ?name } => { ?name }
    { ?name, ... } => { ?name, ... }
end;

define macro method-definer
    { define ?modifiers method ?name ?noise end }
      => { define ?modifiers %%method ?name ?noise end }
  modifiers:
    { } => { }
    { ?name ... } => { ?name ... }
end;

define macro variable-definer
    { define variable ?bindings } => { define %%variable ?bindings }
end;


// Classes that need to be pre-defined.

define primary abstract open %%class <object> ()
  //
  // The class of the instance.  Non-abstract classes automatically override
  // the init-value to be the correct class.
  slot %object-class, type: <class>, setter: #f, init-value: <object>
end;

define abstract open class <functional-object> (<object>)
end;


define abstract class <boolean> (<object>) end;
define class <true> (<boolean>) end;
define class <false> (<boolean>) end;

define class <function> (<object>) end;
define class <method> (<function>) end;
define class <generic-function> (<function>) end;

define class <symbol> (<object>) end;

define class <type> (<object>) end;
define class <singleton> (<type>) end;
define class <union> (<type>) end;
define class <limited-integer> (<type>) end;
define class <byte-character-type> (<type>) end;
define class <class> (<type>)
  slot unique-id :: <fixed-integer>, required-init-keyword: unique-id:;
end;

define abstract open class <number> (<object>) end;
define abstract open class <complex> (<number>) end;
define abstract class <real> (<complex>) end;
define abstract class <rational> (<real>) end;
define abstract class <integer> (<rational>) end;

define functional class <fixed-integer> (<integer>)
  slot value :: <fixed-integer>, init-value: 0;
end;

define class <extended-integer> (<integer>) end;

define abstract class <float> (<real>) end;

define functional class <single-float> (<float>)
  slot value :: <single-float>, init-value: 0.0s0;
end;

define functional class <double-float> (<float>)
  slot value :: <double-float>, init-value: 0.0d0;
end;

define functional class <extended-float> (<float>)
  slot value :: <extended-float>, init-value: 0.0x0;
end;

define abstract open class <collection> (<object>) end;
define abstract open class <explicit-key-collection> (<collection>) end;
define abstract open class <stretchy-collection> (<collection>) end;
define abstract open class <mutable-collection> (<collection>) end;
define abstract open class <sequence> (<collection>) end;
define abstract open class <mutable-explicit-key-collection>
    (<mutable-collection>, <explicit-key-collection>)
end;
define abstract open class <mutable-sequence>
    (<mutable-collection>, <sequence>)
end;
define abstract open class <array> (<mutable-sequence>) end;
define abstract open class <vector> (<array>) end;
define abstract open class <string> (<mutable-sequence>) end;
define class <simple-object-vector> (<vector>) end;
define class <unicode-string> (<vector>, <string>) end;
define class <byte-string> (<vector>, <string>) end;
define abstract class <list> (<mutable-sequence>) end;
define class <empty-list> (<list>) end;
define class <pair> (<list>) end;

define constant $max-char-code = #xffff;
define constant <char-code>
  = limited(<fixed-integer>, min: 0, max: $max-char-code);
define functional class <character> (<object>)
  slot value :: <char-code>, required-init-keyword: code:;
end;

define constant <byte-character> = make(<byte-character-type>);

define class <value-cell> (<object>)
  slot value, required-init-keyword: value:
end;

define functional class <raw-pointer> (<object>)
  slot value :: <raw-pointer>, required-init-keyword: value:;
end;

define class <catcher> (<object>)
end;


// Functions that need to be defined.

define open generic %make-method
    (specializers :: <list>, result-types :: <list>,
     rest-result-type :: <type>, entry :: <method>)
    => res :: <method>;
define open generic %make-gf () => res :: <generic-function>;
define open generic add-method (gf :: <generic-function>, meth :: <method>)
    => (new :: <method>, old :: union(<method>, <false>));
define open generic check-type (value, type :: <type>) => value;
define open generic error (msg, #rest args) => res :: type-or();
define open generic make (class :: <class>, #all-keys) => thing;
define open generic initialize (instance, #all-keys);
define open generic \== (x, y) => res :: <boolean>;
define open generic \= (x, y) => res :: <boolean>;
define open generic \< (x, y) => res :: <boolean>;
define open generic \+ (x :: <number>, y :: <number>) => res :: <number>;
define open generic \- (x :: <number>, y :: <number>) => res :: <number>;
define open generic even? (x :: <integer>) => res :: <boolean>;
define open generic odd? (x :: <integer>) => res :: <boolean>;
define open generic %closure-ref
    (closure :: <method>, index :: <fixed-integer>) => res :: <object>;
define open generic %make-next-method-cookie
    (next-method-info :: <list>, #rest original-args)
    => res :: union(<false>, <function>);
define open generic as (class :: <class>, thing :: <object>)
    => result :: <object>;

define open generic make-catcher (saved-state :: <raw-pointer>)
    => res :: <catcher>;
define open generic disable-catcher (catcher :: <catcher>) => ();
define open generic throw
    (catcher :: <catcher>, values :: <simple-object-vector>)
    => res :: type-or();
define open generic make-exit-function (catcher :: <catcher>)
    => res :: <function>;

define open generic push-unwind-protect (cleanup-function :: <function>) => ();
define open generic pop-unwind-protect () => ();

define open generic value (x) => value :: <object>;
define open generic value-setter (x, y) => value;


// Methods that are nice to have by default.

define constant catch
  = method (saved-state :: <raw-pointer>, thunk :: <function>)
      thunk(saved-state);
    end;

define inline method vector (#rest things) => res :: <simple-object-vector>;
  things;
end;

define movable method list (#rest things) => res :: <list>;
  as(<list>, things);
end;

define inline method \< (x :: <fixed-integer>, y :: <fixed-integer>)
    => res :: <boolean>;
  %%primitive fixnum-< (x, y);
end;

define inline method \== (x :: <fixed-integer>, y :: <fixed-integer>)
    => res :: <boolean>;
  %%primitive fixnum-= (x, y);
end;

define inline method \+ (x :: <fixed-integer>, y :: <fixed-integer>)
    => res :: <fixed-integer>;
  %%primitive fixnum-+ (x, y);
end;

define inline method \- (x :: <fixed-integer>, y :: <fixed-integer>)
    => res :: <fixed-integer>;
  %%primitive fixnum-- (x, y);
end;



// Extra dreck.

define generic values-sequence (sequence :: <sequence>);

define inline method values-sequence (sequence :: <sequence>)
  values-sequence(as(<simple-object-vector>, sequence));
end;

define inline method values-sequence
    (vector :: <simple-object-vector>)
  %%primitive values-sequence (vector);
end;


define generic values (#rest values);

define inline method values (#rest values)
  %%primitive values-sequence (values);
end;


define generic apply (function :: <function>, #rest arguments);

define method apply (function :: <function>, #rest arguments)
  error("Apply wasn't inlined?");
end;
