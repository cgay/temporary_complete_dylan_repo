module: tk
author: Robert Stockton (rgs@cs.cmu.edu)

//======================================================================
//
// Copyright (c) 1994  Carnegie Mellon University
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports, questions, comments, and suggestions should be sent by
// E-mail to the Internet address "gwydion-bugs@cs.cmu.edu".
//
//======================================================================
//
// This file provides support for <window> as an abstract class to which all
// widget classes belong.  It contains a generic initialization routine which
// operates on tables produced by "define-widget".  It also provides the
// "*root-window*" object; generic window operations "configure",
// "configuration", "map-window", "unmap-window", "destroy-window" and "pack";
// and the "std-options" routine which is used to define new "widget-like"
// types (such as "<text-tag>" or menu entries).
//
//======================================================================

// Can represent any Tk widget.  The actual structure of the window is
// maintained on the tk side of the pipe, so we simply maintain a string
// handle that identifies it to tk.
//
define class <window> (<object>)
  slot path :: <string> = "";
  keyword name:,
    type: false-or(<string>),
    init-value: #f;
end class <window>;

// The main "wish" window.  All other windows are typically built underneath
// this one.  (Note that this is defined before the initialization function.
// In this special case, this works anyway.
//
define constant *root-window* :: <window>
  = make(<window>, parent: #f, name: "");

// This function is used to define the behavior of a particular subclass of
// <window> The first parameter is the class, the second is the tk name of
// the class, and all remaining parameters describe keywords which should be
// accepted by "make".
//
define generic define-widget
    (cls :: limited(<class>, subclass-of: <window>), tk-command :: <string>,
     #rest options)
 => ();

// Configure accepts pretty much the same options as initialize, and uses them
// to change the state of the object.
//
define generic configure (widget :: <object>, #all-keys);

// Returns a complete list of options for the given widget.  Each option
// consists of a sequence of the switch name, rdb name, rdb class, default,
// and value.
//
define generic configuration (widget :: <object>) => (result :: <sequence>);

// Make sure that a window is displayed on the screen.  *root-window* is
// unmapped initially, so nothing will appear until you call
// "map-window(*root-window*)".
//
define generic map-window (window :: <window>) => ();

// Remove a window from the display.  This is handy to keep from showing
// intermediate states of newly defined windows.
//
define generic unmap-window (window :: <window>) => ();

// Completely obliterate a window, removing it from the screen and all
// knowledge of mankind.
//
define generic destroy-window (window :: <window>) => ();

// Implements the general Tcl/TK "pack" command.
//
define generic pack
    (window :: <window>, #all-keys) => (window :: <window>);

// Removes a window from the packer's knowledge -- (i.e. unmaps it.)
//
define generic unpack
    (window :: <window>) => (window :: <window>);

// Returns a sequence of strings corresponding to all of the keywords in
// "options" which are members of "window-options" or which correspond to the
// standard options "background", "borderwidth", "cursor", "foreground", or
// "relief".  If "accept-pack-options" is true, then it accepts the keywords
// which are processed by the packer, but does not include them in the result.
// If any other keywords are specified, an error is signalled.
//
define generic std-options
    (window-options :: <sequence>, accept-pack-options :: <boolean>,
     options :: <sequence>)
 => (result :: <sequence>);


//==========================================================================
//				Packer support
//==========================================================================

// Strips the last '.' separated element off of the given string.  This will
// convert the 'path' for a window into the 'path' for that window's parent.
//
define method window-parent (name :: <string>) => (parent :: <string>);
  for (last-dot = #f then if (name[index] == '.') index else last-dot end if,
       index from 1 below size(name))
  finally
    case
      last-dot => copy-sequence(name, end: last-dot);
      otherwise => ".";
    end case;
  end for;
end method window-parent;
       
define method window-parent (window :: <window>) => (parent :: <string>);
  window-parent(window.path);
end method window-parent;

//==========================================================================

// See description of the generic above.
//
define method pack
    (window :: <window>, #rest rest,
     #key fill, in: parent, after, before, side = "left",
          expand = #f, padx, pady, anchor, #all-keys)
 => (window :: <window>);
  let parent
    = if (parent | after | before) parent else window.window-parent end if;
  put-tk-line("pack ", window,
	      make-option(#"fill", fill),
	      make-option(#"in", parent),
	      make-option(#"after", after),
	      make-option(#"before", before),
	      make-option(#"expand", expand),
	      make-option(#"anchor", anchor),
	      make-option(#"side", side),
	      make-option(#"padx", padx),
	      make-option(#"pady", pady));
  window;
end method pack;

define method unpack (window :: <window>) => (window :: <window>);
  put-tk-line("pack forget ", window);
  window;
end method unpack;

//==========================================================================
//			      <Window> creation
//==========================================================================

// These variables store information about how to make new <window>s.  They
// are updated by "define-widget" below.
//
define constant options-table :: <dictionary> = make(<table>);
define constant tk-command-table :: <dictionary> = make(<table>);
define variable pack-options :: <sequence>
  = #[#"pack", #"name",
	#"after", #"anchor", #"before", #"expand", #"fill", #"in",
	#"padx", #"pady", #"side"];

// See description of the generic above
//
define method define-widget
    (cls :: limited(<class>, subclass-of: <window>), tk-command :: <string>,
     #rest options) => ();
  tk-command-table[cls] := tk-command;
  options-table[cls] := options;
end method define-widget;

// See description of the generic above.
//
define method std-options
    (window-options :: <sequence>, accept-pack-options :: <boolean>,
     options :: <sequence>) => (result :: <sequence>);
  let result :: <sequence> = make(<list>);
  for (key-index from 0 below size(options) by 2,
       value-index from 1 by 2)
    let key = options[key-index];
    let value = options[value-index];
    case
      member?(key, window-options) =>
	result := add!(result, make-option(key, value));
      accept-pack-options & member?(key, pack-options) =>
	#t;
      otherwise =>
	select (key)
	  #"background", #"borderwidth", #"cursor", #"foreground",
	  #"relief" =>
	    result := add!(result, make-option(key, value));
	  otherwise =>
	    error("Option %= not supported for widget.", key)
	end select;
    end case;
  end for;
  result;
end method std-options;

// The base initialization method for all windows just fills in the pathname
// based upon the given name and parent.
//
define method initialize
    (window :: <window>, #next next, #rest keys,
     #key name, in: parent, before, after, pack: do-pack = #t, #all-keys);
  next();
  let name = name | anonymous-name();
  let parent = case
		 parent => tk-as(<string>, parent);
		 after => after.window-parent;
		 before => before.window-parent;
		 otherwise => ".";
	       end case;

  if (empty?(name))
    // Special case for root window
    window.path := "";
  else
    let path-name
      = concatenate(parent, if (parent.last = '.') "" else "." end if, name);
    window.path := path-name;
    let cls = window.object-class;
    let options = std-options(options-table[cls], #t, keys);
    apply(put-tk-line, tk-command-table[cls], " ", path-name, options);
    if (do-pack) apply(pack, window, keys) end if;
  end if;
end method initialize;

define method tk-as
    (cls == <string>, value :: <window>) => (result :: <string>);
  if (value == *root-window*)
    ".";
  else
    value.path;
  end if;
end method tk-as;


//==========================================================================
//			  Generic support functions
//==========================================================================

// Configure accepts pretty much the same options as initialize, and uses them
// to change the state of the object.
//
define method configure
    (window :: <window>, #next next, #rest keys, #all-keys);
  let cls = window.object-class;
  let options = std-options(options-table[cls], #f, keys);
  apply(put-tk-line, window, " configure", options);
  window;
end method configure;

// See description of the generic above
//
define method configuration (widget :: <window>) => (result :: <sequence>);
  let string = call-tk-function(widget.path, " configure");
  parse-tk-list(string, depth: 2);
end method configuration;

//==========================================================================

// See description of the generic function above.
//
define method map-window (window :: <window>) => ();
  put-tk-line("wm deiconify ", window);
end method map-window;

// See description of the generic function above.
//
define method unmap-window (window :: <window>) => ();
  put-tk-line("wm withdraw ", window);
end method unmap-window;

// See description of the generic function above.
//
define method destroy-window (window :: <window>) => ();
  put-tk-line("destroy ", window);
end method destroy-window;

