Module:   dfmc-reader
Synopsis: A tokenizer abstraction for use by the parser.
Author:   CMU, adapted by Keith Playford
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// Derived from the orignal CMU code.
// 
// Copyright (c) 1994  Carnegie Mellon University
// All rights reserved.


// Tokenizer interface.

define primary abstract class <tokenizer> (<object>)
end class <tokenizer>;

// define generic get-token (tokenizer :: <tokenizer>)
//    => (token :: <fragment>, srcloc :: <source-location>);

/*
define generic unget-token
    (tokenizer :: <tokenizer>, token :: <fragment>, 
       srcloc :: <source-location>)
    => ();

define generic note-potential-end-point (tokenizer :: <tokenizer>) => ();

define method note-potential-end-point (tokenizer :: <tokenizer>) => ();
end method note-potential-end-point;
*/

// eof
