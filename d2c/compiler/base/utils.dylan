module: utils
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/utils.dylan,v 1.5 1995/01/09 17:35:24 ram Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

remove-method(print-object,
	      find-method(print-object,
			  list(<object>, <stream>)));

define method print-object (object, stream :: <stream>) => ();
  write('{', stream);
  write-class-name(object, stream);
  write(' ', stream);
  write-address(object, stream);
  write('}', stream);
end;

*default-pretty?* := #t;


// printing utilities.

define method write-class-name (thing, stream) => ();
  let name = thing.object-class.class-name;
  if (name)
    write(as(<string>, name), stream);
  else
    print(thing.object-class, stream);
  end;
end;

define constant $digit-mask = as(<extended-integer>, #xf);

define method write-address (thing, stream) => ();
  write("0x", stream);
  let address = thing.object-address;
  for (shift from -28 below 1 by 4)
    let digit = as(<fixed-integer>, logand(ash(address, shift), $digit-mask));
    if (digit < 10)
      write(digit + 48, stream);
    else
      write(digit + 87, stream);
    end;
  end;
end;

define method pprint-fields (thing, stream, #rest fields) => ();
  pprint-logical-block
    (stream,
     prefix: "{",
     body: method (stream)
	     write-class-name(thing, stream);
	     write(' ', stream);
	     write-address(thing, stream);
	     for (i from 0 below fields.size by 2)
	       if (fields[i])
		 write(", ", stream);
		 pprint-indent(#"block", 2, stream);
		 pprint-newline(#"linear", stream);
		 write(as(<string>, fields[i]), stream);
		 write(": ", stream);
		 pprint-indent(#"block", 4, stream);
		 pprint-newline(#"fill", stream);
		 print(fields[i + 1], stream);
	       end;
	     end;
	   end,
     suffix: "}");
end;



// Flush-happy stream

define class <flush-happy-stream> (<stream>)
  slot target :: <stream>, required-init-keyword: target:;
  slot buffer :: <buffer>;
  slot column :: <fixed-integer>, init-value: 0;
end;

define method stream-extension-get-output-buffer
    (stream :: <flush-happy-stream>)
    => (buf :: <buffer>, next :: <buffer-index>, size :: <buffer-index>);
  let (buf, next, size) = get-output-buffer(stream.target);
  stream.buffer := buf;
  values(buf, next, size);
end;

define constant $newline = as(<integer>, '\n');

define method after-last-newline (buf :: <buffer>, stop :: <buffer-index>)
    => res :: union(<false>, <buffer-index>);
  local
    method repeat (i)
      if (zero?(i))
	#f;
      else
	let i-1 = i - 1;
	if (buf[i-1] == $newline)
	  i;
	else
	  repeat(i-1);
	end;
      end;
    end;
  repeat(stop);
end;

define method stream-extension-release-output-buffer
    (stream :: <flush-happy-stream>, next :: <buffer-index>)
    => ();
  let buf = stream.buffer;
  let after-newline = after-last-newline(buf, next);
  if (after-newline)
    empty-output-buffer(stream.target, after-newline);
    force-secondary-buffers(stream.target);
    stream.column := 0;
    let remaining = next - after-newline;
    unless (zero?(remaining))
      copy-bytes(buf, 0, buf, after-newline, remaining);
    end;
    release-output-buffer(stream.target, remaining);
  else
    release-output-buffer(stream.target, next);
  end;
end;

define method stream-extension-empty-output-buffer
    (stream :: <flush-happy-stream>,
     stop :: <buffer-index>)
    => ();
  let buf = stream.buffer;
  let after-newline = after-last-newline(buf, stop);
  if (after-newline)
    empty-output-buffer(stream.target, after-newline);
    force-secondary-buffers(stream.target);
    let remaining = stop - after-newline;
    unless (zero?(remaining))
      copy-bytes(buf, 0, buf, after-newline, remaining);
      empty-output-buffer(stream.target, remaining);
    end;
    stream.column := remaining;
  else
    empty-output-buffer(stream.target, stop);
    stream.column := stream.column + stop;
  end;
end;

define method stream-extension-force-secondary-buffers
    (stream :: <flush-happy-stream>)
    => ();
  force-secondary-buffers(stream.target);
end;  

define method stream-extension-synchronize (stream :: <flush-happy-stream>)
    => ();
  synchronize(stream.target);
end;

define method close (stream :: <flush-happy-stream>) => ();
  force-output(stream);
end;

define method pprint-logical-block
    (stream :: <flush-happy-stream>,
     #next next-method,
     #key column: ignore :: <integer> = 0,
          prefix :: false-or(<byte-string>),
          per-line-prefix :: false-or(<byte-string>),
          body :: <function>,
          suffix :: false-or(<byte-string>))
    => ();
  let (buf, next) = get-output-buffer(stream);
  let column = stream.column + next;
  release-output-buffer(stream, next);
  next-method(stream, column: column, prefix: prefix,
	      per-line-prefix: per-line-prefix, body: body,
	      suffix: suffix);
end;


*debug-output* := make(<flush-happy-stream>, target: *debug-output*);


// pretty format

define method pretty-format (stream :: <stream>,
			     string :: <byte-string>,
			     #rest args)
  let length = string.size;
  local
    method scan-for-space (stream, start, posn, arg-index)
      if (posn == length)
	maybe-spew(stream, start, posn);
      else
	let char = string[posn];
	if (char == ' ')
	  scan-for-end-of-spaces(stream, start, posn + 1, arg-index);
	elseif (char == '%')
	  maybe-spew(stream, start, posn);
	  let directive = string[posn + 1];
	  if (directive == '%')
	    scan-for-space(stream, posn + 1, posn + 2, arg-index);
	  else
	    format(stream, copy-sequence(string, start: posn, end: posn + 2),
		   args[arg-index]);
	    scan-for-space(stream, posn + 2, posn + 2, arg-index + 1);
	  end;
	else
	  scan-for-space(stream, start, posn + 1, arg-index);
	end;
      end;
    end,
    method scan-for-end-of-spaces(stream, start, posn, arg-index)
      if (posn < length & string[posn] == ' ')
	scan-for-end-of-spaces(stream, start, posn + 1, arg-index);
      else
	maybe-spew(stream, start, posn);
	pprint-newline(#"fill", stream);
	scan-for-space(stream, posn, posn, arg-index);
      end;
    end,
    method maybe-spew (stream, start, stop)
      unless (start == stop)
	write(string, stream, start: start, end: stop);
      end;
    end;
  pprint-logical-block(stream,
		       body: method (stream)
			       scan-for-space(stream, 0, 0, 0);
			     end);
end;

define method report-condition (condition :: type-or(<simple-error>,
						     <simple-warning>,
						     <simple-restart>),
				stream :: <stream>)
  apply(pretty-format, stream,
	condition.condition-format-string,
	condition.condition-format-arguments);
end;


// Simple utility functions.

define method dformat(#rest args) => ();
  apply(format, *debug-output*, args);
end;


define constant assert
  = method (value) => ();
      unless (value)
	error("Assertion failed.");
      end;
    end;

define constant compiler-warning = method (#rest args) => ();
  apply(format, *debug-output*, args);
  format(*debug-output*, "\n");
end;


define generic key-of
  (value, collection :: <collection>, #key test :: <function>, default)
 => res;

define method key-of
    (value, coll :: <collection>,
     #key test :: <function> = \==, default = #f)
 => res;
  find-key(method (x) test(value, x) end,
           coll, failure: default)
end method;

define method key-of
    (value, coll :: <list>,
     #key  test :: <function> = \==, default = #f)
 => res;
  block (done)
    for (els = coll then els.tail,
         pos :: <fixed-integer> from 0,
         while ~(els == #()))
      if (test(value, els.head))
        done(pos);
      end;
      finally default;
    end for;
  end;
end method;


define method list?(obj);
  instance?(obj, <list>);
end;

define method pair?(obj);
  instance?(obj, <pair>);
end;
