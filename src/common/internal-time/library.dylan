module: Dylan-User
author: Ben Folk-Williams
synopsis: Library and module definitions.
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

define library Internal-Time
  use Dylan;

  export
    Internal-Time;
//    Interval-Timers; // Not yet 
end library Internal-Time;

define module Internal-Time-Interface
  use Dylan;
  use Extensions;
  use Extern;

  export
    <tms>,
    tms-stime,
    tms-utime,
    $SC-CLK-TCK,
    times,
    sysconf;
end module Internal-Time-Interface;

define module Internal-Time
  use Dylan;
  use Extensions;
  use Internal-Time-Interface;

  export
    <internal-time>,
    $internal-time-units-per-second,
    $maximum-internal-time,
    get-internal-run-time,
    get-internal-real-time;
end module Internal-Time;

/* Not done yet!
define module Interval-Timer-Interface
  use Dylan;
  use Extentions;
  use Extern;

  export
    <itimerval>,
    it-interval,
    it-value,
    it-interval-setter,
    it-value-setter,
    <timeval>,
    tv-sec,
    tv-usec,
    tv-sec-setter,
    tv-usec-setter,
    ITIMER-REAL,
    ITIMER-VIRTUAL,
    ITIMER-PROF,
    getitimer,
    setitimer;
end module Interval-Timer-Interface;

define module Interval-Timers
  use Dylan;
  use Extensions;
  use Interval-Timer-Interface;
  use Internal-Time;

  export
    <interval-timer-handle>,
    
    set-interval-timer,
    clear-interval-timer,
    disable-interval-timer,
    enable-interval-timer,
    time-until-next-trigger;
end module Interval-Timers;
*/

