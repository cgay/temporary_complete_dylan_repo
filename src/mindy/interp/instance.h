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
* $Header: /home/housel/work/rcs/gd/src/mindy/interp/instance.h,v 1.8 1994/11/30 16:18:51 rgs Exp $
*
\**********************************************************************/


enum slot_allocation {
    alloc_INSTANCE, alloc_CLASS, alloc_SUBCLASS, alloc_CONSTANT, alloc_VIRTUAL,
    alloc_Kinds
};

struct library;

struct defined_class {
    obj_t class;
    enum type_Id type_id;
    boolean abstract_p;
    boolean sealed_p;
    struct library *library;
    int (*scavenge)(struct object *ptr);
    obj_t (*transport)(obj_t object);
    void (*print)(obj_t object);
    obj_t debug_name;
    obj_t superclasses;
    obj_t cpl;
    obj_t direct_subclasses;
    obj_t all_subclasses;

    obj_t new_slots;
    obj_t all_slots;
    obj_t new_initargs;
    obj_t all_initargs;
    obj_t inheriteds;

    obj_t instance_positions;
    int instance_length;
    obj_t instance_layout;

    obj_t subclass_positions;
    obj_t subclass_slots;
    obj_t subclass_layout;
};

#define DC(o) obj_ptr(struct defined_class *, o)

extern obj_t obj_DefinedClassClass;

extern void describe(obj_t thing);

extern obj_t make_defined_class(obj_t debug_name, struct library *library);
extern void init_defined_class(obj_t class, obj_t slots,
			       obj_t initargs, obj_t inheriteds);
