/**********************************************************************\
*
*  Copyright (C) 1994, Carnegie Mellon University
*  All rights reserved.
*
*  This code was produced by the Gwydion Project at Carnegie Mellon
*  University.  If you are interested in using this code, contact
*  "Scott.Fahlman@cs.cmu.edu" (Internet).
*
***********************************************************************
*
* $Header: /home/housel/work/rcs/gd/src/mindy/interp/print.h,v 1.3 1994/05/31 18:11:37 nkramer Exp $
*
* This file does whatever.
*
\**********************************************************************/

extern void prin1(obj_t object);
extern void print(obj_t object);
extern void print_nonzero_in_binary(int number);
extern void print_number_in_binary(int number);
extern void format(char *fmt, ...);
extern int count_format_args(char *fmt);
extern void vformat(char *fmt, obj_t *args);

extern void def_printer(obj_t class, void (*print_fn)(obj_t object));
