module: File-system
author: Nick Kramer
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/file-system.dylan,v 1.3 1996/09/04 16:47:11 nkramer Exp $
copyright: Copyright (c) 1995, 1996  Carnegie Mellon University
	   All rights reserved.

// This library consists of various functions for manipulating files
// and file names.

// This implementation can be separated into functions that work on
// *files*, and functions that work on *filenames*.  Functions that
// work on files are currently only implemented for Unix systems (and
// PC systems that have Unix-like commands installed), and work by
// spawning processes like "rm" and "cmp".  (ie, this implementation
// does *not* invoke system calls like unlink() directly)

// On the other hand, *filename* commands work on both Unix and
// Microsoft systems.  Throughout this code, it is assumed that '/' is
// *a* legal path separator, although it does not have to be the only
// one.  ('/' is indeed a legal separator in MS-Windows)

// Terminology:

//    file -- What file systems consist of.  "file" usually usually
//    means a "normal" file, but sometimes can include special files
//    like directories.

//    filename -- a byte-string which points to a file.

//    absolute filename -- A filename which points to the same file no
//    matter what the current working directory (or drive) is.

//    relative filename -- A filename which is not an absolute filename.

//    directory-name -- A filename, except that the file must be a
//    directory and not some other kind of file.

//    search path -- a single byte-string which consists of directory
//    names separated by $search-path-separator

//    path -- Another word for filename.

//    filename-prefix -- Everything up to and including the final
//    path-separator in the filename

//    pathless-filename -- Everything in the filename after the
//    filename-prefix.

//    extensionless-filename -- Everything in the filename before the
//    filename-extension.

//    base-filename -- That part of the filename between the last
//    path separator and the filename-extension.

//    filename-extension -- Everything including and after the final
//    "." of a filename (including the period).  An exception is made
//    if the pathless filename is ".", "..", or starts with a "." and
//    has no additional dots.  In these cases, the filename-extension
//    is empty.

//    For all filenames, 
//       filename = concatenate(filename.filename-prefix, 
//			      filename.base-filename, 
//			      filename.filename-extension)


// Simple filename manipulations

define constant <filename> = <byte-string>;

define constant $search-path-separator = #if (compiled-for-x86-win32)
                                            ';';
                                         #else 
                                            ':';
                                         #endif

define constant foo = 0;  // reset indentation

define function search-path-separator? (c :: <character>)
 => answer :: <boolean>;
  c == $search-path-separator;
end function search-path-separator?;

// One of potentially several path separators.  Use path-separator?()
// if you want to find out if the character you're looking at is a
// path separator.
//
define constant $a-path-separator = '/';

define function path-separator? (c :: <character>) => answer :: <boolean>;
  #if (compiled-for-x86-win32)
     (c == '/') | (c == '\\') | (c == ':');
  #else
     c == '/';
  #endif
end function path-separator?;

define constant foo2 = 0;  // reset indentation

// Internal.  One past the last character of the prefix; 0 if there is
// no prefix.
//
define function end-of-prefix (filename :: <filename>) 
 => index :: <integer>;
  block (return)
    for (index from filename.size - 1 to 0 by -1)
      if (filename[index].path-separator?)
	return(index);
      end if;
    end for;
    -1;
  end block;
end function end-of-prefix;

define function filename-prefix (filename :: <filename>)
 => prefix :: <filename>;
  let end-pos = filename.end-of-prefix;
  if (end-pos == -1)
    "";   // copy-sequence chokes if end-pos == -1.  Perhaps it
          // shouldn't, but that's what it does
  else
    copy-sequence(filename, end: end-pos);
  end if;
end function filename-prefix;

// Internal.  filename.size if a dot is not found.
//
define function start-of-extension (filename :: <filename>)
 => index :: <integer>;
  block (return)
    let last-dot = block (break)
		     for (index from filename.size - 1 to 0 by -1)
		       if (filename[index] == '.')
			 break(index);
		       end if;
		     end for;
		     return(filename.size);
		   end block;

    let prefix-end = filename.end-of-prefix;
    // last-dot ~= filename.size, or else it would have returned by now
    if (last-dot == prefix-end)  
      // special case 1: pathless-filename is of the form ".*"
      filename.size;
    elseif (last-dot == prefix-end + 1 & filename[prefix-end] == '.')
      // special case 2: pathless-filename is ".."
      filename.size;
    else
      last-dot;
    end if;
  end block;
end function start-of-extension;

define function filename-extension (filename :: <filename>)
 => extension :: <filename>;
  copy-sequence(filename, start: filename.start-of-extension);
end function filename-extension;

define function base-filename (filename :: <filename>)
 => basename :: <filename>;
  copy-sequence(filename, start: filename.end-of-prefix,
		end: filename.start-of-extension);
end function base-filename;

define function pathless-filename (filename :: <filename>)
 => pathless-filename :: <filename>;
  copy-sequence(filename, start: filename.end-of-prefix);
end function pathless-filename;

define function extensionless-filename (filename :: <filename>)
 => extensionless :: <filename>;
  copy-sequence(filename, end: filename.start-of-extension);
end function extensionless-filename;

// ### Should have as-absolute-filename


// Finding files

// If found, returns the file stream open for input, and a path to the
// file (not necessarily fully qualified).
//
// dir-sequence is a sequence of directory names.
//
define method find-and-open-file 
    (pathless-name :: <filename>, dir-sequence :: <sequence>)
 => (stream :: false-or(<stream>), filename :: false-or(<filename>));
  block (return)
    local
      method try (filename :: <filename>) => ();
	block (punt)
	  return(make(<file-stream>, locator: filename, direction: #"input"),
		 filename);
	exception (<file-does-not-exist-error>)
	  #f;
	end block;
      end method try;
    for (dir in dir-sequence)
      try(concatenate(dir, as(<string>, $a-path-separator), pathless-name));
    end for;
    values(#f, #f);
  end block;
end method find-and-open-file;

define function find-file
    (pathless-name :: <filename>, dir-sequence :: <sequence>)
 => filename :: false-or(<filename>);
  let (worthless-stream, filename) 
    = find-and-open-file(pathless-name, dir-sequence);
  if (worthless-stream)
    close(worthless-stream);
  end if;
  filename;
end function find-file;


// getcwd -- Mindy defines this in the System module.  d2c does not.

#if (~mindy)

define function getcwd () => cwd :: <byte-string>;
  // Something about getdrive() on MS-windows.  include <direct.h>
  let buffer = make(<buffer>, size: 1024);
  if (zero?(call-out("getcwd", #"long",
		     #"ptr", buffer-address(buffer),
		     #"int", 1024)))
    error("Can't get the current directory.");
  else
    let len = block (return)
		for (index :: <integer> from 0 below 1024)
		  if (buffer[index].zero?)
		    return(index);
		  end if;
		end for;
		error("Can't get the current directory.");
	      end block;
    let result = make(<byte-string>, size: len);
    for (index :: <integer> from 0 below len)
      result[index] := as(<character>, buffer[index]);
    end for;
    result;
  end if;
end function getcwd;

#endif

// ### Should also include the current drive, but does not.
//
define function get-current-directory () => cwd :: <byte-string>;
  getcwd();
end function get-current-directory;


// File functions
//
// Currently implemented only on Unix and machines that have Unix-ish
// utilities

define function delete-file (filename :: <string>) => ();
  let rm-command = concatenate("rm -f ", filename);
  if (system(rm-command) ~== 0)
    cerror("so what", "rm failed?");
  end if;
end function delete-file;

define function rename-file
    (old-filename :: <string>, new-filename :: <string>)
 => ();
  let mv-command = concatenate("mv -f ", old-filename, " ", new-filename);
  if (system(mv-command) ~== 0)
    cerror("so what", "mv failed?");
  end if;
end function rename-file;

// Returns false if one of the files isn't there
//
define function files-identical? 
    (filename1 :: <string>, filename2 :: <string>)
 => answer :: <boolean>;
  let cmp-command = concatenate("cmp -s ", filename1, " ", filename2);
  // cmp will return non-zero if they are different, if a file's not
  // found, or if cmp somehow fails to execute.
  system(cmp-command) == 0;
end function files-identical?;
