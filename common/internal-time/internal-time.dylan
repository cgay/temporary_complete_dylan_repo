module: Internal-Time
author: Ben Folk-Williams
synopsis: The Internal Time library.
copyright: See below.

//======================================================================
//
// Copyright (c) 1996  Carnegie Mellon University
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

/// Constants.
/// These are all exported.
///
define constant <internal-time> = <integer>;
define constant $internal-time-units-per-second = sysconf($SC-CLK-TCK);
define constant $maximum-internal-time = $maximum-integer;

/// Functions.
/// All exported.
///

// get-internal-run-time
//
define method get-internal-run-time () => run-time :: <internal-time>;
  let (ignore, time) = times();
  time.tms-utime + time.tms-stime;
end method get-internal-run-time;

// get-internal-real-time
//
define method get-internal-real-time () => real-time :: <internal-time>;
  let real-time = times(); // Don't want to return second return value of times
  real-time;
end method get-internal-real-time;

