module: top-level-forms
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/front/tlf.dylan,v 1.3 1995/03/23 21:57:13 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

define constant $Top-Level-Forms = make(<stretchy-vector>);

define abstract class <top-level-form> (<object>)
end;

define abstract class <define-tlf> (<top-level-form>)
end;

define abstract class <simple-define-tlf> (<define-tlf>)
  slot tlf-defn :: <definition>, init-keyword: defn:;
end;

define method print-object (tlf :: <simple-define-tlf>, stream :: <stream>)
    => ();
  pprint-fields(tlf, stream, name: tlf.tlf-defn.defn-name);
end;

// process-top-level-form -- exported.
//
// Called by the parser whenever it finishes another top-level form.
//
define generic process-top-level-form (form :: <constituent>) => ();

define method process-top-level-form (form :: <local-declaration>) => ();
  error("Local declarations cannot appear directly at top level.");
end;

// finalize-top-level-form -- exported.
//
// Called by the main driver on each top level form in $Top-Level-Forms
// after everything has been parsed.
//
define generic finalize-top-level-form (tlf :: <top-level-form>) => ();

// convert-top-level-form
//
define generic convert-top-level-form
    (builder :: <fer-builder>, tlf :: <top-level-form>)
    => ();


// Utilities.

define method extract-modifiers (where :: <string>, name :: <symbol>,
				 modifiers :: <simple-object-vector>,
				 #rest names)
  for (modifier in modifiers)
    unless (member?(modifier.token-symbol, names))
      error("Bogus modifier for %s %s: %s",
	    where, name, modifier.token-symbol);
    end;
  end;
  local method find-modifier (name)
	  block (return)
	    for (modifier in modifiers)
	      if (modifier.token-symbol == name)
		return(#t);
	      end;
	    end;
	    #f;
	  end;
	end;
  apply(values, map(find-modifier, names));
end;

define method extract-properties (where :: <string>,
				  plist :: <simple-object-vector>,
				  #rest keywords)
  for (prop in plist)
    unless (member?(prop.prop-keyword.token-literal.literal-value, keywords))
      compiler-error("Bogus keyword in %s: %=", where, prop.prop-keyword);
    end;
  end;
  local method find-key (key)
	  block (return)
	    for (prop in plist)
	      if (prop.prop-keyword.token-literal.literal-value == key)
		return(prop.prop-value);
	      end;
	    end;
	    #f;
	  end;
	end;
  apply(values, map(find-key, keywords));
end;
