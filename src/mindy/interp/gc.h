/**********************************************************************\
*
*  Copyright (c) 1994  Carnegie Mellon University
*  All rights reserved.
*  
*  Use and copying of this software and preparation of derivative
*  works based on this software are permitted, including commercial
*  use, provided that the following conditions are observed:
*  
*  1. This copyright notice must be retained in full on any copies
*     and on appropriate parts of any derivative works.
*  2. Documentation (paper or online) accompanying any system that
*     incorporates this software, or any part of it, must acknowledge
*     the contribution of the Gwydion Project at Carnegie Mellon
*     University.
*  
*  This software is made available "as is".  Neither the authors nor
*  Carnegie Mellon University make any warranty about the software,
*  its performance, or its conformity to any specification.
*  
*  Bug reports, questions, comments, and suggestions should be sent by
*  E-mail to the Internet address "gwydion-bugs@cs.cmu.edu".
*
***********************************************************************
*
* $Header: /home/housel/work/rcs/gd/src/mindy/interp/gc.h,v 1.5 1994/11/03 22:19:17 wlott Exp $
*
\**********************************************************************/


extern obj_t alloc(obj_t class, int bytes);
extern void shrink(obj_t obj, int new_bytes);
extern void scavenge(obj_t *addr);
extern obj_t transport(obj_t obj, int bytes);

extern void collect_garbage(void);

extern boolean TimeToGC;

#define ForwardingMarker ((obj_t)(0xDEADBEEF))
