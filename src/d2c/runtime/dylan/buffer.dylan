module: dylan-viscera
author: ram+@cs.cmu.edu
synopsis: <buffer> and <byte-vector>
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/runtime/dylan/buffer.dylan,v 1.10 1996/07/12 02:17:56 bfw Exp $


c-include("string.h");

define /* exported */ constant <byte> =
  limited(<integer>, min: 0, max: 255);
define /* exported */ constant <buffer-index> = <integer>;
define /* exported */ constant $maximum-buffer-size = $maximum-integer;


define /* exported */ class <byte-vector> (<simple-vector>)
  sealed slot %element :: <byte>,
    init-value: 0, init-keyword: fill:,
    sizer: size, size-init-value: 0, size-init-keyword: size:;
end;

define sealed domain make (singleton(<byte-vector>));

define /* exported */ class <buffer> (<simple-vector>)
  slot buffer-next :: <buffer-index>, init-value: 0, init-keyword: next:;
  slot buffer-end :: <buffer-index>, init-value: 0, init-keyword: end:;
  sealed slot %element :: <byte>,
    init-value: 0, init-keyword: fill:,
    sizer: size, size-init-value: 0, size-init-keyword: size:;
end class;

define sealed domain make (singleton(<buffer>));

define sealed inline method element
    (vec :: <byte-vector>, index :: <integer>,
     #key default = $not-supplied)
    => element :: <object>; // because of default:
  if (index >= 0 & index < vec.size)
    %element(vec, index);
  elseif (default == $not-supplied)
    element-error(vec, index);
  else
    default;
  end;
end;

define sealed inline method element-setter
    (new-value :: <byte>, vec :: <byte-vector>, index :: <integer>)
    => new-value :: <byte>;
  if (index >= 0 & index < vec.size)
    %element(vec, index) := new-value;
  else
    element-error(vec, index);
  end;
end;

define sealed inline method element
    (buf :: <buffer>, index :: <buffer-index>,
     #key default = $not-supplied)
 => element :: <object>; // because of default:
  if (index >= 0 & index < buf.size)
    %element(buf, index);
  elseif (default == $not-supplied)
    element-error(buf, index);
  else
    default;
  end;
end;

define sealed inline method element-setter
    (new-value :: <byte>, buf :: <buffer>, index :: <buffer-index>)
 => new-value :: <byte>;
  if (index >= 0 & index < buf.size)
    %element(buf, index) := new-value;
  else
    element-error(buf, index);
  end;
end;


define constant <byte-like> = type-union(<unicode-string>,
					 <buffer>, 
					 <byte-string>, 
					 <byte-vector>);

// Copy bytes from src to dest (which may overlap.)  
define /* exported */ generic copy-bytes 
  (dest :: <byte-like>, dest-start :: <integer>, 
   src :: <byte-like>, src-start :: <integer>,
   count :: <integer>)
 => ();

// These methods are all the same modulo specializers, but are replicated so
// that the vector-elements works.  Also, the mixed type operations can use
// memcpy, since the source and destination can't overlap.

define method copy-bytes 
    (dest :: <byte-vector>, dstart :: <integer>,
     src :: <byte-vector>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-string>, dstart :: <integer>,
     src :: <byte-vector>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-vector>, dstart :: <integer>,
     src :: <byte-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-string>, dstart :: <integer>,
     src :: <byte-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <buffer>, dstart :: <integer>,
     src :: <buffer>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-string>, dstart :: <integer>,
     src :: <buffer>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <buffer>, dstart :: <integer>,
     src :: <byte-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-vector>, dstart :: <integer>,
     src :: <buffer>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <buffer>, dstart :: <integer>,
     src :: <byte-vector>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <unicode-string>, dstart :: <integer>,
     src :: <unicode-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + (2 * dstart),
	   ptr: %%primitive(vector-elements, src) + (2 * sstart),
	   int: (2 * count));
end method;

define /* exported */ method buffer-address (x :: <buffer>)
 => res :: <raw-pointer>;
  %%primitive(vector-elements, x);
end method;
