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
* $Header: /home/housel/work/rcs/gd/src/mindy/interp/def.c,v 1.8 1994/06/11 02:23:22 wlott Exp $
*
* This file does whatever.
*
\**********************************************************************/

#include "mindy.h"
#include "module.h"
#include "sym.h"
#include "thread.h"
#include "func.h"
#include "list.h"
#include "bool.h"
#include "obj.h"
#include "def.h"
#include "type.h"
#include "instance.h"
#include "error.h"
#include "class.h"


/* Stuff to define builtin stuff. */

void define(char *name, obj_t value)
{
    obj_t namesym = symbol(name);
    struct variable *var;

    define_variable(module_BuiltinStuff, namesym, var_Variable);
    var = find_variable(module_BuiltinStuff, namesym, FALSE, TRUE);
    var->value = value;
    var->function = func_Maybe;
}

void define_constant(char *name, obj_t value)
{
    obj_t namesym = symbol(name);
    struct variable *var;

    define_variable(module_BuiltinStuff, namesym, var_Constant);
    var = find_variable(module_BuiltinStuff, namesym, FALSE, TRUE);
    var->value = value;
    var->function = func_Maybe;
}

void define_function(char *name, obj_t specializers, boolean restp,
		     obj_t keywords, boolean all_keys, obj_t result_type,
		     obj_t (*func)())
{
    define_constant(name,
		    make_builtin_method(name, specializers, restp, keywords,
					all_keys, result_type, func));
}

void define_generic_function(char *name, int req_args, boolean restp,
			     obj_t keys, boolean all_keys, obj_t result_types,
			     obj_t more_results_type)
{
    obj_t namesym = symbol(name);
    struct variable *var;
    obj_t gf = make_generic_function(namesym, req_args, restp, keys, all_keys,
				     result_types, more_results_type);
    obj_t methods;

    define_variable(module_BuiltinStuff, namesym, var_GenericFunction);
    var = find_variable(module_BuiltinStuff, namesym, FALSE, TRUE);
    if (var->value != obj_Unbound)
	methods = generic_function_methods(var->value);
    else
	methods = obj_Nil;
    var->value = gf;
    var->function = func_Always;

    while (methods != obj_Nil) {
	add_method(gf, HEAD(methods));
	methods = TAIL(methods);
    }
}

void define_method(char *name, obj_t specializers, boolean restp,
		   obj_t keywords, boolean all_keys, obj_t result_type,
		   obj_t (*func)())
{
    obj_t namesym = symbol(name);
    obj_t method = make_builtin_method(name, specializers, restp,
				       keywords, all_keys, result_type, func);
    struct variable *var;
    obj_t gf;

    define_variable(module_BuiltinStuff, namesym, var_Method);
    var = find_variable(module_BuiltinStuff, namesym, FALSE, TRUE);
    gf = var->value;
    if (gf == obj_Unbound) {
	gf = make_default_generic_function(namesym, method);
	var->value = gf;
	var->function = func_Always;
    }
    add_method(gf, method);
}

void define_class(char *name, obj_t value)
{
    obj_t namesym = symbol(name);
    struct variable *var;

    define_variable(module_BuiltinStuff, namesym, var_Class);
    var = find_variable(module_BuiltinStuff, namesym, FALSE, TRUE);
    var->value = value;
    var->function = func_No;
}


/* Stuff to define/initialize defined stuff. */

static obj_t init_variable(obj_t var_obj, obj_t value, obj_t type)
{
    struct variable *var = obj_rawptr(var_obj);

    var->value = value;
    var->type = type;
    if (type != obj_False && subtypep(type, obj_FunctionClass))
	var->function = func_Always;
    else if (instancep(value, obj_FunctionClass))
	var->function = func_Yes;
    else
	var->function = func_No;

    return var->name;
}

static obj_t defmethod(obj_t var_obj, obj_t method)
{
    struct variable *var = obj_rawptr(var_obj);
    obj_t gf = var->value;
    obj_t old;

    if (gf == obj_Unbound) {
	gf = make_default_generic_function(var->name, method);
	var->value = gf;
	var->function = func_Always;
    }
    old = add_method(gf, method);

    if (old != obj_False)
	error("Definition of %= clashes with %=", method, old);

    return var->name;
}

static obj_t defgeneric(obj_t var_obj, obj_t signature, obj_t restp,
			obj_t keywords, obj_t all_keys, obj_t result_types,
			obj_t more_results_type)
{
    struct variable *var = obj_rawptr(var_obj);
    obj_t gf = var->value;

    if (more_results_type == obj_True)
	more_results_type = obj_ObjectClass;

    if (gf == obj_Unbound) {
	var->value = make_generic_function(var->name, length(signature),
					   restp != obj_False, keywords,
					   all_keys != obj_False, result_types,
					   more_results_type);
	var->function = func_Always;
    }
    else
	set_gf_signature(gf, length(signature), restp != obj_False, keywords,
			 all_keys != obj_False, result_types,
			 more_results_type);

    return var->name;
}

static obj_t defclass1(obj_t class, obj_t superclasses)
{
    setup_class_supers(class, superclasses);

    return class;
}

static obj_t defclass2(obj_t class, obj_t slots)
{
    init_defined_class(class, slots);
    /* init_defined_class doesn't return */
    lose("init_defined_class actually returned?\n");
    return NULL;
}

static obj_t defslot(obj_t getter, obj_t setter)
{
    struct variable *var;

    if (setter != obj_False) {
	var = obj_rawptr(setter);
	if (var->value == obj_Unbound)
	    var->value = make_generic_function(var->name, 2, FALSE, obj_False,
					       FALSE, list1(obj_ObjectClass),
					       obj_False);
    }

    var = obj_rawptr(getter);
    if (var->value == obj_Unbound)
	var->value = make_generic_function(var->name, 1, FALSE, obj_False,
					   FALSE, list1(obj_ObjectClass),
					   obj_False);

    return var->name;
}


/* Init stuff. */

void init_def_functions(void)
{
    define_function("init-variable",
		    list3(obj_ObjectClass, obj_ObjectClass, obj_ObjectClass),
		    FALSE, obj_False, FALSE, obj_ObjectClass, init_variable);
    define_function("%define-method", list2(obj_ObjectClass, obj_ObjectClass),
		    FALSE, obj_False, FALSE, obj_ObjectClass, defmethod);
    define_function("%define-generic",
		    listn(7, obj_ObjectClass, obj_ObjectClass, obj_ObjectClass,
			  obj_ObjectClass, obj_ObjectClass, obj_ObjectClass,
			  obj_ObjectClass),
		    FALSE, obj_Nil, FALSE, obj_ObjectClass, defgeneric);
    define_function("%define-class-1",
		    list2(obj_ObjectClass, obj_ObjectClass),
		    FALSE, obj_False, FALSE, obj_ObjectClass, defclass1);
    define_function("%define-class-2",
		    list2(obj_ObjectClass, obj_ObjectClass),
		    FALSE, obj_False, FALSE, obj_ObjectClass, defclass2);
    define_function("%define-slot", list2(obj_ObjectClass, obj_ObjectClass),
		    FALSE, obj_False, FALSE, obj_ObjectClass, defslot);
}
