Module:       streams-internals
Synopsis:     Abstract classes and generic definitions for external streams
Author:       Scott McKay, Marc Ferguson, Eliot Miranda
Copyright:    Original Code is Copyright (c) 1994-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define open abstract class <external-stream-accessor> (<object>)
end class <external-stream-accessor>;

define open abstract class <external-stream> (<basic-stream>)
  keyword locator:;
  keyword if-exists:;
  keyword if-does-not-exist:;
end class <external-stream>;

define open generic accessor 
    (stream :: <external-stream>) => (the-accessor :: false-or(<external-stream-accessor>));

define open generic accessor-setter 
    (the-accessor :: false-or(<external-stream-accessor>), stream :: <external-stream>)
 => (the-accessor :: false-or(<external-stream-accessor>));

define constant $open-external-streams :: <table> = make(<table>);

define function close-external-streams () => ()
  for (external-stream in $open-external-streams)
      close(external-stream);
  end for;
end function;

define open method initialize
    (the-stream :: <external-stream>, 
     #rest keys,
     #key locator = #f,
     already-registered? = #f) => ()
  //  This method has registered the open stream for automatic closing
  //  on application exit.  Let other methods know.
  apply(next-method, the-stream, already-registered?: #t, keys);
  // Use the stream as its own key.
  unless (already-registered?)
    $open-external-streams[the-stream] := the-stream; 
  end unless;
end method;

/// Basic stream protocol

define method close
    (stream :: <external-stream>,
     #rest keys, #key abort? = #f, wait? = #t, synchronize? = #f,
     already-unregistered? = #f) => ()
  if (stream-open?(stream))
    unless (abort?)
      if (synchronize?)
	force-output(stream, synchronize?: synchronize?);
      elseif (wait?)
	force-output(stream, synchronize?: #f);	
      else
	do-force-output(stream)
      end if;
    end unless;
    if (stream.accessor)
      accessor-close(stream.accessor, abort?: abort?, wait?: wait?);
    end if;
    unless (already-unregistered?)
      remove-key!($open-external-streams, stream);
    end unless;
     // Let other methods know that this method has unregistered the
     // stream for automatic closing on application exit.
    apply(next-method, stream, already-unregistered?: #t, keys);
  end if; //  what to do if it isn't open? warn? error? nothing?
end method close;

// Force-output always blocks.  Do-force-output is the non-blocking form
define method force-output
    (stream :: <external-stream>, 
     #key synchronize? :: <boolean> = #f) => ()
  do-force-output(stream);
  wait-for-io-completion(stream);
  if(synchronize?)
    accessor-force-output(stream.accessor, stream);
  end if;
end method force-output;



define method synchronize-output
    (stream :: <external-stream>) => ();
  force-output(stream, synchronize?: #t);
end method;

define method wait-for-io-completion
    (stream :: <external-stream>) => ()
  if (stream.accessor)
    accessor-wait-for-completion(stream.accessor);
  end;
end method;

define method newline-sequence (stream :: <external-stream>)
 => (elements :: <string>)
  accessor-newline-sequence(stream.accessor)
end method newline-sequence;


/// Accessor Protocol

// An attempt at a portable flexible interface to OS read/write/seek
// functionality.  Legal values for TYPE might include #"file", #"pipe",
// #"tcp", #"udp".
//--- Dubious idea Eliot, we can't dispatch on this.
// Legal values for LOCATOR depend on TYPE.  For TYPE == #"file",
// LOCATOR is a string or <locator> naming a file.
define open generic platform-accessor-class
    (type :: <symbol>, locator :: <object>)
 => (class /* ---*** :: subclass(<external-stream-accessor>) */);

// Returns the file-handle/file-descriptor/file-pointer from the platform
// accessor class, whichever it is.  Value has to be a <machine-word>
// because win32 file-handles set the high bits.  So once again the lowest
// common denominator wins.

define open generic accessor-fd
  ( the-accessor :: <external-stream-accessor> ) 
=> (the-fd :: false-or(<machine-word>));

// Legal values for direction are #"input", #"output", #"input-output"
// Legal values for if-exists are #"new-version", #"overwrite", #"replace",
//                                #"truncate", #"signal", #"append"
// NB #"append" does _not_ imply unix open(2) append semantics, _only_
// that writing is likely to continue from the end.  So it's merely a
// hint as to where to go first.
// Legal values for if-does-not-exist are #"signal", #"create"
// #all-keys to allow the stream using the accessor to pass through any
// old junk without complaint.
define method new-accessor
    (type :: <symbol>, #rest initargs, #key locator, #all-keys)
 => (accessor :: <external-stream-accessor>)
  let new-one = apply(make, platform-accessor-class(type, locator), initargs);
  apply(accessor-open, new-one, initargs);
  new-one
end method new-accessor;

define open generic accessor-open
    (accessor :: <external-stream-accessor>,
     #key direction, if-exists, if-does-not-exist,
     #all-keys) => ();

define open generic accessor-close
    (accessor :: <external-stream-accessor>,
     #key abort?, wait?)
 => (closed? :: <boolean>);

define open generic accessor-open?
    (accessor :: <external-stream-accessor>)
 => (open? :: <boolean>);

define open generic accessor-preferred-buffer-size
    (accessor :: <external-stream-accessor>)
 => (preferred-buffer-size :: <integer>);

define open generic accessor-read-into!
    (accessor :: <external-stream-accessor>, stream :: <external-stream>,
     offset :: <buffer-index>, count :: <buffer-index>, #key buffer)
 => (nread :: <integer>);

define open generic accessor-write-from
    (accessor :: <external-stream-accessor>, stream :: <external-stream>,
     offset :: <buffer-index>, count :: <buffer-index>, #key buffer,
     return-fresh-buffer?)
 => (nwritten :: <integer>, new-buffer :: <buffer>);

define open generic accessor-force-output
    (accessor :: <external-stream-accessor>,
     stream :: <external-stream>)
 => ();

define open generic accessor-wait-for-completion
    (accessor :: <external-stream-accessor>)
 => ();

// default method does nothing
define method accessor-wait-for-completion
    (accessor :: <external-stream-accessor>)
 => ()
  ignore(accessor);
end method;

define open generic accessor-synchronize
    (accessor :: <external-stream-accessor>,
     stream :: <external-stream>)
 => ();

define open generic accessor-newline-sequence
    (accessor :: <external-stream-accessor>)
 => (newline-sequence :: <sequence>);


// Provide default methods for 'accessor-force-output' and 'accessor-synchronize'
// that do nothing, since that is correct for most filesystem interfaces.
define method accessor-force-output
    (accessor :: <external-stream-accessor>,
     stream :: <external-stream>) => ()
  #f
end method accessor-force-output;

define method accessor-synchronize
    (accessor :: <external-stream-accessor>,
     stream :: <external-stream>) => ()
  #f
end method accessor-synchronize;


// Simple scheme for tracking open accessors for reclaiming file descriptors
// whilst debugging.
define variable *open-accessors* = make(<table>, size: 10);

/*---*** andrewa: this isn't used...
define method close-open-accessors () => ()
  map(accessor-close, key-sequence(*open-accessors*))
end method close-open-accessors;
*/


/// File stream conditions

define sealed class <file-error> (<error>)
  constant slot file-error-locator,
    required-init-keyword: locator:;
end class <file-error>;

define sealed class <file-exists-error> (<file-error>)
end class <file-exists-error>;

define sealed class <file-does-not-exist-error> (<file-error>)
end class <file-does-not-exist-error>;

define sealed class <invalid-file-permissions-error> (<file-error>)
end class <invalid-file-permissions-error>;


/// Condition reporting

define method condition-to-string
    (error :: <file-exists-error>) => (string :: <string>)
  format-to-string("File %s exists", file-error-locator(error))
end method condition-to-string;

define method condition-to-string
    (error :: <file-does-not-exist-error>) => (string :: <string>)
  format-to-string("File %s does not exist", file-error-locator(error))
end method condition-to-string;

define method condition-to-string
    (error :: <invalid-file-permissions-error>) => (string :: <string>)
  format-to-string("Invalid file permissions for file %s", 
		   file-error-locator(error))
end method condition-to-string;
