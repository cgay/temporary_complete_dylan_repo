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
* $Header: /home/housel/work/rcs/gd/src/mindy/interp/module.c,v 1.20 1994/11/28 15:49:01 wlott Exp $
*
* This file implements the module system.
*
\**********************************************************************/

#include "../compat/std-c.h"

#include "mindy.h"
#include "gc.h"
#include "sym.h"
#include "list.h"
#include "bool.h"
#include "str.h"
#include "obj.h"
#include "module.h"
#include "class.h"
#include "type.h"
#include "thread.h"
#include "func.h"
#include "def.h"
#include "load.h"
#include "error.h"
#include "print.h"

obj_t obj_Unbound = NULL;
static obj_t obj_UnboundClass = NULL;

static boolean InitializingVars = TRUE;

struct bucket {
    obj_t symbol;
    void *datum;
    struct bucket *next;
};

struct table {
    int entries;
    int threshold;
    int length;
    struct bucket **table;
};

struct library {
    obj_t name;
    struct defn *defn;
    struct table *modules;
    boolean loading;
    boolean busy;
    boolean completed;
    struct library *next;
};

struct entry {
    obj_t name;
    void *datum;
    boolean exported;
    obj_t origin;
};

struct module {
    obj_t name;
    struct library *home;
    struct defn *defn;
    struct table *variables;
    boolean busy;
    boolean completed;
    struct module *next;
};

struct var {
    boolean created;
    struct var *next;
    struct variable variable;
};

static struct table *LibraryTable = NULL;
static struct library *Libraries = NULL;
static struct module *Modules = NULL;
static struct var *Vars = NULL;

static struct library *library_Dylan = NULL;
struct module *module_BuiltinStuff = NULL;

static struct module *make_module(obj_t name, struct library *home);
static struct var *make_var(obj_t name, struct module *home, enum var_kind k);


/* Table manipulation stuff. */

static struct table *make_table(void)
{
    struct table *table = (struct table *)malloc(sizeof(struct table));

    table->entries = 0;
    table->threshold = 96;
    table->length = 64;
    table->table = (struct bucket **)malloc(sizeof(struct bucket *)*64);
    memset(table->table, 0, sizeof(struct bucket *)*64);

    return table;
}

static void *table_lookup(struct table *table, obj_t symbol)
{
    unsigned hash = sym_hash(symbol);
    int index = hash % table->length;
    struct bucket *bucket;

    for (bucket = table->table[index]; bucket != NULL; bucket = bucket->next)
	if (bucket->symbol == symbol)
	    return bucket->datum;
    return NULL;
}

static void rehash_table(struct table *table)
{
    int length = table->length;
    int new_length = (length < 1024) ? (length << 1) : (length + 1024);
    struct bucket **new_table
	= (struct bucket **)malloc(sizeof(struct bucket *) * new_length);
    int i;

    memset(new_table, 0, sizeof(struct bucket *) * new_length);

    for (i = 0; i < length; i++) {
	struct bucket *bucket, *next;

	for (bucket = table->table[i]; bucket != NULL; bucket = next) {
	    int index = sym_hash(bucket->symbol) % new_length;

	    next = bucket->next;
	    bucket->next = new_table[index];
	    new_table[index] = bucket;
	}
    }

    free(table->table);

    table->threshold = (new_length * 3) >> 1;
    table->length = new_length;
    table->table = new_table;
}

static void table_add(struct table *table, obj_t symbol, void *datum)
{
    unsigned hash = sym_hash(symbol);
    int index = hash % table->length;
    struct bucket *bucket;

    for (bucket = table->table[index]; bucket != NULL; bucket = bucket->next)
	if (bucket->symbol == symbol) {
	    bucket->datum = datum;
	    return;
	}

    bucket = (struct bucket *)malloc(sizeof(struct bucket));
    bucket->symbol = symbol;
    bucket->datum = datum;
    bucket->next = table->table[index];
    table->table[index] = bucket;

    table->entries++;
    if (table->entries >= table->threshold)
	rehash_table(table);
}

static void *table_remove(struct table *table, obj_t symbol)
{
    unsigned hash = sym_hash(symbol);
    int index = hash % table->length;
    struct bucket *bucket, **prev;

    for (prev = &table->table[index];
	 (bucket = *prev) != NULL;
	 prev = &bucket->next)
	if (bucket->symbol == symbol) {
	    void *res = bucket->datum;
	    *prev = bucket->next;
	    free(bucket);
	    table->entries--;
	    return res;
	}

    return NULL;
}


/* Utilities */

static void vmake_entry(struct table *table, obj_t name, void *datum,
		       boolean exported, char *template, va_list ap1, va_list ap2)
{
    char *ptr;
    int len;
    char *origin;
    struct entry *old_entry = table_lookup(table, name);
    struct entry *entry;

    if (old_entry && old_entry->datum == datum)
	return;

    entry = (struct entry *)malloc(sizeof(struct entry));

    entry->name = name;
    entry->datum = datum;
    entry->exported = exported;

    len = strlen(template);
    for (ptr = template; *ptr != '\0'; ptr++) {
	if (*ptr == '%') {
	    len--;
	    switch (*++ptr) {
	      case '%':
		break;
	      case '=':
		len += strlen(sym_name(va_arg(ap1, obj_t)));
		break;
	      default:
		lose("Bogus thing in origin template: %%%c", *ptr);
	    }
	}
    }

    entry->origin = alloc_byte_string(len);
    origin = (char *)string_chars(entry->origin);

    for(ptr = template; *ptr != '\0'; ptr++) {
	if (*ptr == '%') {
	    switch (*++ptr) {
	      case '%':
		*origin++ = '%';
		break;
	      case '=':
		{
		    char *name = sym_name(va_arg(ap2, obj_t));
		    while (*name != '\0')
			*origin++ = *name++;
		}
		break;
	    }
	}
	else
	    *origin++ = *ptr;
    }
    *origin = '\0';

    if (old_entry)
	error("%s clashes with %s", entry->origin, old_entry->origin);

    table_add(table, name, entry);
}
#if _USING_PROTOTYPES_
static void make_entry(struct table *table, obj_t name, void *datum,
		       boolean exported, char *template, ...)
{
    va_list ap1, ap2;
    va_start(ap1, template);
    va_start(ap2, template);
    vmake_entry(table, name, datum, exported, template, ap1, ap2);
    va_end(ap1);
    va_end(ap2);
}
#else
static void make_entry(va_alist) va_dcl
{
    va_list ap1, ap2;
    struct table *table;
    obj_t name;
    void *datum;
    boolean exported;
    char *template;
    va_start(ap1);
    va_start(ap2);
    table = va_arg(ap1, struct table *);
    table = va_arg(ap2, struct table *);
    name = va_arg(ap1, obj_t);
    name = va_arg(ap2, obj_t);
    datum = va_arg(ap1, void *);
    datum = va_arg(ap2, void *);
    exported = va_arg(ap1, boolean);
    exported = va_arg(ap2, boolean);
    template = va_arg(ap1, char *);
    template = va_arg(ap2, char *);
    vmake_entry(table, name, datum, exported, template, ap1, ap2);
    va_end(ap1);
    va_end(ap2);
}
#endif

static obj_t prepend_prefix(obj_t name, struct use *use)
{
    char *prefix;
    char *local_name;
    obj_t res;

    if (use->prefix == obj_False)
	return name;

    prefix = (char *)obj_ptr(struct string *, use->prefix)->chars;
    local_name = (char *)malloc(strlen(prefix) + strlen(sym_name(name)) + 1);
    strcpy(local_name, prefix);
    strcat(local_name, sym_name(name));
    res = symbol(local_name);
    free(local_name);

    return res;
}

static obj_t prefix_or_rename(obj_t name, struct use *use)
{
    obj_t ptr;

    for (ptr = use->rename; ptr != obj_Nil; ptr = TAIL(ptr))
	if (name == HEAD(HEAD(ptr)))
	    return TAIL(HEAD(ptr));
    return prepend_prefix(name, use);
}

static boolean exported(obj_t name, struct use *use)
{
    return use->export == obj_True || memq(name, use->export);
}


/* Libraries. */

static struct library *make_library(obj_t name)
{
    struct library *library = malloc(sizeof(struct library));

    library->name = name;
    library->defn = NULL;
    library->modules = make_table();
    library->completed = FALSE;
    library->loading = FALSE;
    library->busy = FALSE;
    library->next = Libraries;
    Libraries = library;

    table_add(LibraryTable, name, library);

    return library;
}

struct library *find_library(obj_t name, boolean createp)
{
    struct library *library = table_lookup(LibraryTable, name);

    if (library == NULL && createp) {
	struct defn *defn = malloc(sizeof(struct defn));
	struct use *use1 = malloc(sizeof(struct use));
	struct use *use2 = malloc(sizeof(struct use));
	obj_t dylan_user = symbol("Dylan-User");
	struct module *module;

	library = make_library(name);
	module = make_module(dylan_user, library);

	module->defn = defn;

	defn->name = dylan_user;
	defn->use = use1;
	defn->exports = obj_Nil;
	defn->creates = obj_Nil;

	use1->name = symbol("Dylan");
	use1->import = obj_True;
	use1->prefix = obj_False;
	use1->exclude = obj_Nil;
	use1->rename = obj_Nil;
	use1->export = obj_Nil;
	use1->next = use2;

	use2->name = symbol("Extensions");
	use2->import = obj_True;
	use2->prefix = obj_False;
	use2->exclude = obj_Nil;
	use2->rename = obj_Nil;
	use2->export = obj_Nil;
	use2->next = NULL;

	make_entry(library->modules, module->name, module, FALSE,
		   "module %= implicitly defined in library %=",
		   module->name, library->name);
    }

    return library;
}

void define_library(struct defn *defn)
{
    struct library *library = find_library(defn->name, TRUE);

    if (library->defn)
	error("Library %= multiply defined.\n", defn->name);

    library->defn = defn;
}

static void complete_library(struct library *library)
{
    obj_t ptr;
    struct defn *defn;
    struct use *use;

    defn = library->defn;
    if (defn == NULL) {
	if (library->loading)
	    error("needed the definition of library %= before the "
		  "define library was found",
		  library->name);
	library->loading = TRUE;
	load_library(library->name);
	if (library->defn == NULL)
	    error("loaded library %=, but never found the define library.\n",
		  library->name);
	library->loading = FALSE;
	return;
    }

    if (library->busy)
	error("Library %= circularly defined.\n", library->name);
    library->busy = TRUE;

    for (ptr = defn->exports; ptr != obj_Nil; ptr = TAIL(ptr)) {
	obj_t name = HEAD(ptr);
	struct module *module = make_module(name, library);

	make_entry(library->modules, name, module, TRUE,
		   "module %= defined in library %=",
		   name, library->name);
    }

    for (use = library->defn->use; use != NULL; use = use->next) {
	obj_t use_name = use->name;
	struct library *used_library = find_library(use_name, TRUE);
	obj_t imports = obj_Nil;

	if (!used_library->completed)
	    complete_library(used_library);

	if (use->import == obj_True) {
	    struct table *modules = used_library->modules;
	    int i;
	    for (i = 0; i < modules->length; i++) {
		struct bucket *bucket;
		for (bucket = modules->table[i];
		     bucket != NULL;
		     bucket = bucket->next) {
		    struct entry *entry = (struct entry *)bucket->datum;
		    obj_t name = entry->name;
		    if (entry->exported && !memq(name, use->exclude)) {
			obj_t local_name = prefix_or_rename(name, use);
			make_entry(library->modules, local_name, entry->datum,
				   exported(local_name, use),
				   name == local_name
				   ? "module %= imported from library %="
				   :"module %= imported from library %= as %=",
				   name, use_name, local_name);
			imports = pair(local_name, imports);
		    }
		}
	    }
	}
	else {
	    for (ptr = use->import; ptr != obj_Nil; ptr = TAIL(ptr)) {
		obj_t name = HEAD(ptr);
		obj_t local_name = prepend_prefix(name, use);
		struct entry *entry
		    = table_lookup(used_library->modules, name);
		if (!entry || !entry->exported)
		    error("library %= can't import module %= from library %= "
			  "because it isn't exported.\n",
			  library->name, name, use_name);
		make_entry(library->modules, local_name, entry->datum,
			   exported(local_name, use),
			   name == local_name
			    ? "module %= imported from library %="
			    : "module %= imported from library %= as %=",
			   name, use_name, local_name);
		imports = pair(local_name, imports);
	    }
	    for (ptr = use->rename; ptr != obj_Nil; ptr = TAIL(ptr)) {
		obj_t rename = HEAD(ptr);
		obj_t name = HEAD(rename);
		obj_t local_name = TAIL(rename);
		struct entry *entry
		    = table_lookup(used_library->modules, name);
		if (!entry || !entry->exported)
		    error("library %= can't import module %= from library %="
			  "because it isn't exported.\n",
			  library->name, name, use_name);
		make_entry(library->modules, local_name, entry->datum,
			   exported(local_name, use),
			   name == local_name
			    ? "module %= imported from library %="
			    : "module %= imported from library %= as %=",
			   name, use_name, local_name);
		imports = pair(local_name, imports);
	    }
	}
	if (use->export != obj_True)
	    for (ptr = use->export; ptr != obj_Nil; ptr = TAIL(ptr))
		if (!memq(HEAD(ptr), imports))
		    error("library %= can't re-export module %= because it "
			  "doesn't import it in the first place",
			  library->name, HEAD(ptr));
    }

    library->busy = FALSE;
    library->completed = TRUE;
}


/* Modules */

static struct module *make_module(obj_t name, struct library *home)
{
    struct module *module = malloc(sizeof(struct module));

    module->name = name;
    module->home = home;
    module->defn = NULL;
    module->variables = make_table();
    module->busy = FALSE;
    module->completed = FALSE;
    module->next = Modules;
    Modules = module;

    return module;
}

struct module *find_module(struct library *library, obj_t name,
			   boolean lose_if_not_there, boolean lose_if_imported)
{
    struct entry *entry;
    struct module *module;

    if ((entry = table_lookup(library->modules, name)) == NULL) {
	if (!lose_if_not_there)
	    return NULL;

	if (!library->completed) {
	    complete_library(library);
	    if ((entry = table_lookup(library->modules, name)) == NULL)
		error("Unknown module %= in library %=",
		      name, library->name);
	}
	else
	    error("Unknown module %= in library %=", name, library->name);
    }

    module = entry->datum;

    if (lose_if_imported && module->home != library)
	error("Can't add code to module %= in library %= because it "
	      "is imported from library %=",
	      module->name,
	      library->name,
	      module->home->name);

    return module;
}

void define_module(struct library *library, struct defn *defn)
{
    struct entry *entry;
    struct module *module;

    entry = table_lookup(library->modules, defn->name);
    if (entry == NULL && !library->completed) {
	complete_library(library);
	entry = table_lookup(library->modules, defn->name);
    }
    if (entry == NULL) {
	module = make_module(defn->name, library);
	make_entry(library->modules, defn->name, module, FALSE,
		   "module %= internal to library %=",
		   defn->name, library->name);
    }
    else {
	module = entry->datum;

	if (module->home != library)
	    error("Can't define %s in library %= because its home "
		    "is library %=.\n",
		  entry->origin, library->name, module->home->name);

	if (module->defn)
	    error("Module %= multiply defined.\n", defn->name);
    }

    module->defn = defn;
}

static void
    make_and_export_var(struct module *module, obj_t name, boolean created)
{
    struct entry *entry;
    struct var *var;

    entry = table_lookup(module->variables, name);
    if (entry) {
	var = entry->datum;
	if (var->variable.home == module) {
	    table_remove(module->variables, name);
	    free(entry);
	}
	else
	    var = make_var(name, module, var_Assumed);
    }
    else
	var = make_var(name, module, var_Assumed);

    make_entry(module->variables, name, var, TRUE,
	       created
	       ? "variable %= created in module %="
	       : "variable %= defined in module %=",
	       name, module->name);

    var->created = created;
}

static void complete_module(struct module *module)
{
    obj_t ptr;
    struct defn *defn;
    struct use *use;

    if (module->busy)
	error("Module %= circularly defined.", module->name);
    module->busy = TRUE;

    defn = module->defn;
    if (defn == NULL)
	error("Attempt to use module %= before it is defined.", module->name);

    for (ptr = defn->exports; ptr != obj_Nil; ptr = TAIL(ptr))
	make_and_export_var(module, HEAD(ptr), FALSE);
    for (ptr = defn->creates; ptr != obj_Nil; ptr = TAIL(ptr))
	make_and_export_var(module, HEAD(ptr), TRUE);

    for (use = module->defn->use; use != NULL; use = use->next) {
	obj_t use_name = use->name;
	struct module *used_module;
	obj_t imports = obj_Nil;

	if (module->name == symbol("Dylan-User"))
	    used_module = find_module(library_Dylan, use_name, TRUE, FALSE);
	else
	    used_module = find_module(module->home, use_name, TRUE, FALSE);

	if (!used_module->completed)
	    complete_module(used_module);

	if (use->import == obj_True) {
	    struct table *modules = used_module->variables;
	    int i;
	    for (i = 0; i < modules->length; i++) {
		struct bucket *bucket;
		for (bucket = modules->table[i];
		     bucket != NULL;
		     bucket = bucket->next) {
		    struct entry *entry = (struct entry *)bucket->datum;
		    obj_t name = entry->name;
		    if (entry->exported && !memq(name, use->exclude)) {
			obj_t local_name = prefix_or_rename(name, use);
			make_entry(module->variables, local_name, entry->datum,
				   exported(local_name, use),
				   name == local_name
				   ? "variable %= imported from module %="
				   : "variable %= imported from "
				     "module %= as %=",
				   name, use_name, local_name);
			imports = pair(local_name, imports);
		    }
		}
	    }
	}
	else {
	    for (ptr = use->import; ptr != obj_Nil; ptr = TAIL(ptr)) {
		obj_t name = HEAD(ptr);
		obj_t local_name = prepend_prefix(name, use);
		struct entry *entry
		    = table_lookup(used_module->variables, name);
		if (!entry || !entry->exported)
		    error("module %= can't import variable %= from module %= "
			  "because it isn't exported.",
			  module->name, name, use_name);
		make_entry(module->variables, local_name, entry->datum,
			   exported(local_name, use),
			   name == local_name
			    ? "variable %= imported from module %="
			    : "variable %= imported from module %= as %=",
			   name, use_name, local_name);
		imports = pair(local_name, imports);
	    }
	    for (ptr = use->rename; ptr != obj_Nil; ptr = TAIL(ptr)) {
		obj_t rename = HEAD(ptr);
		obj_t name = HEAD(rename);
		obj_t local_name = TAIL(rename);
		struct entry *entry
		    = table_lookup(used_module->variables, name);
		if (!entry || !entry->exported)
		    error("module %= can't import variable %= from module %="
			  "because it isn't exported.",
			  module->name, name, use_name);
		make_entry(module->variables, local_name, entry->datum,
			   exported(local_name, use),
			   name == local_name
			    ? "variable %= imported from module %="
			    : "variable %= imported from module %= as %=",
			   name, use_name, local_name);
		imports = pair(local_name, imports);
	    }
	}
	if (use->export != obj_True)
	    for (ptr = use->export; ptr != obj_Nil; ptr = TAIL(ptr))
		if (!memq(HEAD(ptr), imports))
		    error("module %= can't re-export variable %= because it "
			  "doesn't import it in the first place",
			  module->name, HEAD(ptr));
    }

    module->busy = FALSE;
    module->completed = TRUE;
}


/* Variables. */

static struct var *make_var(obj_t name, struct module *home,enum var_kind kind)
{
    struct var *var = malloc(sizeof(struct var));

    var->created = FALSE;
    var->next = Vars;
    Vars = var;

    var->variable.name = name;
    var->variable.home = home;
    var->variable.defined = FALSE;
    var->variable.kind = kind;
    var->variable.value = obj_Unbound;
    var->variable.type = obj_False;
    var->variable.function = func_Maybe;
    var->variable.ref_file = obj_False;
    var->variable.ref_line = 0;

    return var;
}

struct var *find_var(struct module *module, obj_t name, boolean writeable,
		     boolean createp)
{
    struct entry *entry = table_lookup(module->variables, name);
    struct var *var;

    if (entry == NULL) {
	if (createp) {
	    if (!module->completed && !InitializingVars) {
		complete_module(module);
		entry = table_lookup(module->variables, name);
	    }
	}
	else
	    return NULL;
    }
    if (entry == NULL) {
	var = make_var(name, module,
		       writeable ? var_AssumedWriteable : var_Assumed);
	make_entry(module->variables, name, var, FALSE,
		   "variable %= internal to module %=",
		   name, module->name);
    }
    else {
	var = entry->datum;
	if (writeable) {
	    switch (var->variable.kind) {
	      case var_Assumed:
		var->variable.kind = var_AssumedWriteable;
		break;
	      case var_AssumedWriteable:
	      case var_Variable:
		break;
	      default:
		error("Constant %= in module %= library %= is not changeable.",
		      name, module->name, module->home->name);
	    }
	}
    }
    return var;
}

struct variable
    *find_variable(struct module *module, obj_t name, boolean writeable,
		   boolean createp)
{
    struct var *var = find_var(module, name, writeable, createp);

    if (var)
	return &var->variable;
    else
	return NULL;
}

void define_variable(struct module *module, obj_t name, enum var_kind kind)
{
    struct var *var = find_var(module, name, kind == var_Variable, TRUE);

    switch (var->variable.kind) {
      case var_Assumed:
	if (kind != var_Method)
	    var->variable.kind = kind;
	break;
      case var_AssumedWriteable:
	if (kind == var_Variable)
	    var->variable.kind = var_Variable;
	else if (kind != var_Method)
	    error("Constant %= in module %= library %= is not changeable.",
		  name, module->name, module->home->name);
	break;
      default:
	if (kind != var_Method)
	    error("variable %= in module %= multiply defined.",
		  name, module->name);
	break;
    }

    if (var->created) {
	if (var->variable.home == module)
	    error("variable %= must be defined by a user of module %=\n",
		  name, module->name);
	else if (kind!=var_Method && var->variable.home->home!=module->home)
	    error("variable %= must be defined in library %=, not %=\n",
		  name, var->variable.home->home->name,
		  module->home->name);
    }
    else {
	if (kind != var_Method && var->variable.home != module)
	    error("variable %= must be defined in module %=, not %=\n",
		  name, var->variable.home->name, module->name);
    }

    var->variable.defined = TRUE;
}


/* Debugger support. */

void list_libraries(void)
{
    struct library *library;

    for (library = Libraries; library != NULL; library = library->next) {
	fputs(sym_name(library->name), stdout);
	if (library->completed)
	    printf("\n");
	else if (library->defn)
	    printf(" [defined, but not filled in.]\n");
	else
	    printf(" [no definition]\n");
    }
}

obj_t library_name(struct library *library)
{
    return library->name;
}

void list_modules(struct library *library)
{
    struct table *table = library->modules;
    int i;
    struct bucket *bucket;
    
    for (i = 0; i < table->length; i++) {
	for (bucket = table->table[i]; bucket != NULL; bucket = bucket->next) {
	    struct entry *entry = bucket->datum;
	    struct module *module = entry->datum;

	    printf("%c%c ",
		   entry->exported ? 'x' : ' ',
		   module->home == library ? ' ' : 'i');
	    fputs(sym_name(entry->name), stdout);
	    if (module->completed)
		printf("\n");
	    else if (module->defn)
		printf(" [defined, but not filled in.]\n");
	    else
		printf(" [no definition]\n");
	}
    }
}

obj_t module_name(struct module *module)
{
    return module->name;
}



/* GC stuff. */

static int scav_unbound(struct object *ptr)
{
    return sizeof(struct object);
}

static obj_t trans_unbound(obj_t unbound)
{
    return transport(unbound, sizeof(struct object));
}

static void scav_use(struct use *use)
{
    scavenge(&use->name);
    scavenge(&use->import);
    scavenge(&use->prefix);
    scavenge(&use->exclude);
    scavenge(&use->rename);
    scavenge(&use->export);
}

static void scav_defn(struct defn *defn)
{
    struct use *use;

    scavenge(&defn->name);
    scavenge(&defn->exports);
    scavenge(&defn->creates);

    for (use = defn->use; use != NULL; use = use->next)
	scav_use(use);
}

static void scav_table(struct table *table, boolean of_entries)
{
    int i;
    struct bucket *bucket;
    
    for (i = 0; i < table->length; i++) {
	for (bucket = table->table[i]; bucket != NULL; bucket = bucket->next) {
	    scavenge(&bucket->symbol);
	    if (of_entries) {
		struct entry *entry = bucket->datum;
		scavenge(&entry->name);
		scavenge(&entry->origin);
	    }
	}
    }
}

static void scav_var(struct var *var)
{
    scavenge(&var->variable.name);
    scavenge(&var->variable.value);
    scavenge(&var->variable.type);
    scavenge(&var->variable.ref_file);
}

static void scav_module(struct module *module)
{
    scavenge(&module->name);
    scav_defn(module->defn);
    scav_table(module->variables, TRUE);
}

static void scav_library(struct library *library)
{
    scavenge(&library->name);
    scav_defn(library->defn);
    scav_table(library->modules, TRUE);
}

void scavenge_module_roots(void)
{
    struct library *library;
    struct module *module;
    struct var *var;

    scav_table(LibraryTable, FALSE);
    for (library = Libraries; library != NULL; library = library->next)
	scav_library(library);
    for (module = Modules; module != NULL; module = module->next)
	scav_module(module);
    for (var = Vars; var != NULL; var = var->next)
	scav_var(var);
    scavenge(&obj_Unbound);
    scavenge(&obj_UnboundClass);
}


/* Initialization stuff. */

void make_module_classes(void)
{
    obj_UnboundClass = make_builtin_class(scav_unbound, trans_unbound);
}

void init_modules(void)
{
    obj_t dylan = symbol("Dylan");
    obj_t stuff = symbol("Builtin-Stuff");

    LibraryTable = make_table();

    library_Dylan = find_library(dylan, TRUE);

    {
	/* Define the dylan-user library. */
	struct defn *defn = malloc(sizeof(*defn));
	struct use *use = malloc(sizeof(*use));
	defn->name = symbol("Dylan-User");
	defn->use = use;
	defn->exports = obj_Nil;
	defn->creates = NULL;
	use->name = dylan;
	use->import = obj_True;
	use->prefix = obj_False;
	use->exclude = obj_Nil;
	use->rename = obj_Nil;
	use->export = obj_Nil;
	use->next = NULL;
	define_library(defn);
    }
	
    module_BuiltinStuff = make_module(stuff, library_Dylan);
    make_entry(library_Dylan->modules, stuff, module_BuiltinStuff, FALSE,
	       "module %= internal to library %=", stuff, dylan);

    obj_Unbound = alloc(obj_UnboundClass, sizeof(struct object));
}

void init_module_classes(void)
{
    init_builtin_class(obj_UnboundClass, "<unbound-marker>",
		       obj_ObjectClass, NULL);
}

void done_initializing_vars(void)
{
    InitializingVars = FALSE;
}

void finalize_modules(void)
{
    struct library *library;
    struct module *module;
    struct var *var;
    boolean warning_printed = FALSE;

    for (library = Libraries; library != NULL; library = library->next)
	if (!library->completed)
	    complete_library(library);
    for (module = Modules; module != NULL; module = module->next)
	if (!module->completed)
	    complete_module(module);

    for (var = Vars; var != NULL; var = var->next) {
	if (var->variable.defined) {
	    switch (var->variable.kind) {
	      case var_Assumed:
		var->variable.kind = var_GenericFunction;
		break;

	      case var_AssumedWriteable:
		error("Constant %= in module %= library %= is not changeable.",
		      var->variable.name, var->variable.home->name,
		      var->variable.home->home->name);
		break;

	      default:
		break;
	    }
	}
    }

    for (library = Libraries; library != NULL; library = library->next) {
	boolean library_printed = FALSE;
	for (module = Modules; module != NULL; module = module->next) {
	    if (module->home == library) {
		boolean module_printed = FALSE;
		for (var = Vars; var != NULL; var = var->next) {
		    if (var->variable.home==module && !var->variable.defined) {
			if (!warning_printed) {
			    fprintf(stderr, "Warning: the following variables "
				    "are undefined:\n");
			    warning_printed = TRUE;
			}
			if (!library_printed) {
			    fprintf(stderr, "  in library %s:\n",
				    sym_name(library->name));
			    library_printed = TRUE;
			}
			if (!module_printed) {
			    fprintf(stderr, "    in module %s:\n",
				    sym_name(module->name));
			    module_printed = TRUE;
			}
			fprintf(stderr, "      %s",
				sym_name(var->variable.name));
			if (var->variable.ref_file != obj_False) {
			    fprintf(stderr, " [%s, line %d]",
				    string_chars(var->variable.ref_file),
				    var->variable.ref_line);
			}
			fprintf(stderr, "\n");
		    }
		}
	    }
	}
    }
}
