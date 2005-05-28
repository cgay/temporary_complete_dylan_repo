module:    Dylan-user	
Synopsis:  FFI declarations translated from GTK header files.
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


/* Automatically generated from "library.src"; do not edit. */


define library Glib
  use functional-dylan;
  use C-FFI;
  export Glib;
end library Glib;

define module Glib
  use functional-dylan;
  use C-FFI,
    export: {null-pointer, null-pointer?, pointer-address,
	     pointer-value, pointer-value-setter, size-of,
	     <C-void*>, <C-pointer>, <C-string>, <C-unicode-string>,
	     <C-string*>, <C-unicode-string*>,
	     pointer-cast, destroy,
	     pointer-value-address, c-type-cast,
	     c-callable-wrapper-definer, 
	     \with-c-string, \with-stack-structure } ;
  use machine-words,
    export: {%logior, %logand};


  // from "acconfig.h":

  // from "config.h":
  export $HAVE-VPRINTF, $STDC-HEADERS, $NO-SYS-SIGLIST,
	$G-HAVE---INLINE, $GLIB-MAJOR-VERSION, $GLIB-MINOR-VERSION,
	$GLIB-MICRO-VERSION, $GLIB-INTERFACE-AGE, $GLIB-BINARY-AGE,
	$HAVE-PTHREAD-GETSPECIFIC-POSIX, $SIZEOF-CHAR, $SIZEOF-INT,
	$SIZEOF-LONG, $SIZEOF-LONG-LONG, $SIZEOF-SHORT, $SIZEOF-VOID-P,
	$HAVE-ATEXIT, $HAVE-MEMMOVE, $HAVE-STRERROR, $HAVE-FLOAT-H,
	$HAVE-LIMITS-H;

  // from "glib.h":
  export $G-CAN-INLINE;
  export <gchar*>, <gchar**>, <gchar>, <gshort*>, <gshort**>,
	<gshort>, <glong*>, <glong**>, <glong>, <gint*>, <gint**>, <gint>,
	<gboolean*>, <gboolean**>, <gboolean>;
  export <guchar*>, <guchar**>, <guchar>, <gushort*>, <gushort**>,
	<gushort>, <gulong*>, <gulong**>, <gulong>, <guint*>, <guint**>,
	<guint>;
  export <gfloat*>, <gfloat**>, <gfloat>, <gdouble*>, <gdouble**>,
	<gdouble>;
  export <gpointer*>, <gpointer**>, <gpointer>, <gconstpointer*>,
	<gconstpointer**>, <gconstpointer>;
  export <gssize*>, <gssize**>, <gssize>, <gsize*>, <gsize**>,
	<gsize>, <GQuark*>, <GQuark**>, <GQuark>, <GTime*>, <GTime**>,
	<GTime>;
  export $G-LITTLE-ENDIAN, $G-BIG-ENDIAN, $G-PDP-ENDIAN;
  export <GArray*>, <GArray**>, <GArray>, <GByteArray*>,
	<GByteArray**>, <GByteArray>, <GCompletion*>, <GCompletion**>,
	<GCompletion>, <GDebugKey*>, <GDebugKey**>, <GDebugKey>, <GHook*>,
	<GHook**>, <GHook>, <GHookList*>, <GHookList**>, <GHookList>,
	<GList*>, <GList**>, <GList>, <GNode*>, <GNode**>, <GNode>,
	<GPtrArray*>, <GPtrArray**>, <GPtrArray>, <GScanner*>, <GScanner**>,
	<GScanner>, <GScannerConfig*>, <GScannerConfig**>, <GScannerConfig>,
	<GSList*>, <GSList**>, <GSList>, <GString*>, <GString**>, <GString>,
	<GTuples*>, <GTuples**>, <GTuples>, <GTokenValue*>, <GTokenValue**>,
	<GTokenValue>, <GIOChannel*>, <GIOChannel**>, <GIOChannel>;
  export $G-TRAVERSE-LEAFS, $G-TRAVERSE-NON-LEAFS, $G-TRAVERSE-ALL,
	$G-TRAVERSE-MASK, <GTraverseFlags*>, <GTraverseFlags**>,
	<GTraverseFlags>;
  export $G-IN-ORDER, $G-PRE-ORDER, $G-POST-ORDER, $G-LEVEL-ORDER,
	<GTraverseType*>, <GTraverseType**>, <GTraverseType>,
	$G-LOG-LEVEL-USER-SHIFT, $G-LOG-FLAG-RECURSION, $G-LOG-FLAG-FATAL,
	$G-LOG-LEVEL-ERROR, $G-LOG-LEVEL-CRITICAL, $G-LOG-LEVEL-WARNING,
	$G-LOG-LEVEL-MESSAGE, $G-LOG-LEVEL-INFO, $G-LOG-LEVEL-DEBUG,
	$G-LOG-LEVEL-MASK, <GLogLevelFlags*>, <GLogLevelFlags**>,
	<GLogLevelFlags>, $G-LOG-FATAL-MASK;
  export <GCacheNewFunc*>, <GCacheNewFunc**>, <GCacheNewFunc>,
	<GCacheDupFunc*>, <GCacheDupFunc**>, <GCacheDupFunc>,
	<GCacheDestroyFunc*>, <GCacheDestroyFunc**>, <GCacheDestroyFunc>,
	<GCompareFunc*>, <GCompareFunc**>, <GCompareFunc>,
	<GCompletionFunc*>, <GCompletionFunc**>, <GCompletionFunc>,
	<GDestroyNotify*>, <GDestroyNotify**>, <GDestroyNotify>,
	<GDataForeachFunc*>, <GDataForeachFunc**>, <GDataForeachFunc>,
	<GFunc*>, <GFunc**>, <GFunc>, <GHashFunc*>, <GHashFunc**>,
	<GHashFunc>, <GFreeFunc*>, <GFreeFunc**>, <GFreeFunc>, <GHFunc*>,
	<GHFunc**>, <GHFunc>, <GHRFunc*>, <GHRFunc**>, <GHRFunc>,
	<GHookCompareFunc*>, <GHookCompareFunc**>, <GHookCompareFunc>,
	<GHookFindFunc*>, <GHookFindFunc**>, <GHookFindFunc>,
	<GHookMarshaller*>, <GHookMarshaller**>, <GHookMarshaller>,
	<GHookCheckMarshaller*>, <GHookCheckMarshaller**>,
	<GHookCheckMarshaller>, <GHookFunc*>, <GHookFunc**>, <GHookFunc>,
	<GHookCheckFunc*>, <GHookCheckFunc**>, <GHookCheckFunc>,
	<GHookFreeFunc*>, <GHookFreeFunc**>, <GHookFreeFunc>, <GLogFunc*>,
	<GLogFunc**>, <GLogFunc>, <GNodeTraverseFunc*>,
	<GNodeTraverseFunc**>, <GNodeTraverseFunc>, <GNodeForeachFunc*>,
	<GNodeForeachFunc**>, <GNodeForeachFunc>, <GSearchFunc*>,
	<GSearchFunc**>, <GSearchFunc>, <GScannerMsgFunc*>,
	<GScannerMsgFunc**>, <GScannerMsgFunc>, <GTraverseFunc*>,
	<GTraverseFunc**>, <GTraverseFunc>, <GVoidFunc*>, <GVoidFunc**>,
	<GVoidFunc>;
  export data-value, data-value-setter, next-value, next-value-setter,
	prev-value, prev-value-setter, <_GList>, <_GList*>, data-value,
	data-value-setter, next-value, next-value-setter, <_GSList>,
	<_GSList*>, str-value, str-value-setter, len-value, len-value-setter,
	<_GString>, <_GString*>, data-value, data-value-setter, len-value,
	len-value-setter, <_GArray>, <_GArray*>, data-value,
	data-value-setter, len-value, len-value-setter, <_GByteArray>,
	<_GByteArray*>, pdata-value, pdata-value-setter, len-value,
	len-value-setter, <_GPtrArray>, <_GPtrArray*>, len-value,
	len-value-setter, <_GTuples>, <_GTuples*>, key-value,
	key-value-setter, value-value, value-value-setter, <_GDebugKey>,
	<_GDebugKey*>;
  export g-list-push-allocator, g-list-pop-allocator, g-list-alloc,
	g-list-free, g-list-free-1, g-list-append, g-list-prepend,
	g-list-insert, g-list-insert-sorted, g-list-concat, g-list-remove,
	g-list-remove-link, g-list-reverse, g-list-copy, g-list-nth,
	g-list-find, g-list-find-custom, g-list-position, g-list-index,
	g-list-last, g-list-first, g-list-length, g-list-foreach,
	g-list-sort, g-list-nth-data, g-slist-push-allocator,
	g-slist-pop-allocator, g-slist-alloc, g-slist-free, g-slist-free-1,
	g-slist-append, g-slist-prepend, g-slist-insert,
	g-slist-insert-sorted, g-slist-concat, g-slist-remove,
	g-slist-remove-link, g-slist-reverse, g-slist-copy, g-slist-nth,
	g-slist-find, g-slist-find-custom, g-slist-position, g-slist-index,
	g-slist-last, g-slist-length, g-slist-foreach, g-slist-sort,
	g-slist-nth-data, g-hash-table-new, g-hash-table-destroy,
	g-hash-table-insert, g-hash-table-remove, g-hash-table-lookup,
	g-hash-table-lookup-extended, g-hash-table-freeze, g-hash-table-thaw,
	g-hash-table-foreach, g-hash-table-foreach-remove, g-hash-table-size;
  export g-cache-new, g-cache-destroy, g-cache-insert, g-cache-remove,
	g-cache-key-foreach, g-cache-value-foreach;
  export g-tree-new, g-tree-destroy, g-tree-insert, g-tree-remove,
	g-tree-lookup, g-tree-traverse, g-tree-search, g-tree-height,
	g-tree-nnodes;
  export data-value, data-value-setter, next-value, next-value-setter,
	prev-value, prev-value-setter, parent-value, parent-value-setter,
	children-value, children-value-setter, <_GNode>, <_GNode*>,
	g-node-push-allocator, g-node-pop-allocator, g-node-new,
	g-node-destroy, g-node-unlink, g-node-insert, g-node-insert-before,
	g-node-prepend, g-node-n-nodes, g-node-get-root, g-node-is-ancestor,
	g-node-depth, g-node-find, g-node-traverse, g-node-max-height,
	g-node-children-foreach, g-node-reverse-children, g-node-n-children,
	g-node-nth-child, g-node-last-child, g-node-find-child,
	g-node-child-position, g-node-child-index, g-node-first-sibling,
	g-node-last-sibling, $G-HOOK-FLAG-USER-SHIFT, $G-HOOK-FLAG-ACTIVE,
	$G-HOOK-FLAG-IN-CALL, $G-HOOK-FLAG-MASK, <GHookFlagMask*>,
	<GHookFlagMask**>, <GHookFlagMask>, seq-id-value,
	seq-id-value-setter, hook-size-value, hook-size-value-setter,
	is-setup-value, is-setup-value-setter, hooks-value,
	hooks-value-setter, hook-memchunk-value, hook-memchunk-value-setter,
	hook-free-value, hook-free-value-setter, hook-destroy-value,
	hook-destroy-value-setter, <_GHookList>, <_GHookList*>, data-value,
	data-value-setter, next-value, next-value-setter, prev-value,
	prev-value-setter, ref-count-value, ref-count-value-setter,
	hook-id-value, hook-id-value-setter, flags-value, flags-value-setter,
	func-value, func-value-setter, destroy-value, destroy-value-setter,
	<_GHook>, <_GHook*>, g-hook-list-init, g-hook-list-clear,
	g-hook-alloc, g-hook-free, g-hook-ref, g-hook-unref, g-hook-destroy,
	g-hook-destroy-link, g-hook-prepend, g-hook-insert-before,
	g-hook-insert-sorted, g-hook-get, g-hook-find, g-hook-find-data,
	g-hook-find-func, g-hook-find-func-data, g-hook-first-valid,
	g-hook-next-valid, g-hook-compare-ids, g-hook-list-invoke,
	g-hook-list-invoke-check, g-hook-list-marshal,
	g-hook-list-marshal-check;
  export g-on-error-query, g-on-error-stack-trace;
  export g-log-set-handler, g-log-remove-handler,
	g-log-default-handler, g-log-set-fatal-mask, g-log-set-always-fatal,
	<GPrintFunc*>, <GPrintFunc**>, <GPrintFunc>, g-set-print-handler,
	g-set-printerr-handler, <GErrorFunc*>, <GErrorFunc**>, <GErrorFunc>,
	<GWarningFunc*>, <GWarningFunc**>, <GWarningFunc>,
	g-set-error-handler, g-set-warning-handler, g-set-message-handler;
  export g-malloc, g-malloc0, g-realloc, g-free, g-mem-profile,
	g-mem-check, g-allocator-new, g-allocator-free, $G-ALLOCATOR-LIST,
	$G-ALLOCATOR-SLIST, $G-ALLOCATOR-NODE, $G-ALLOC-ONLY,
	$G-ALLOC-AND-FREE, g-mem-chunk-new, g-mem-chunk-destroy,
	g-mem-chunk-alloc, g-mem-chunk-alloc0, g-mem-chunk-free,
	g-mem-chunk-clean, g-mem-chunk-reset, g-mem-chunk-print,
	g-mem-chunk-info, g-blow-chunks;
  export g-timer-new, g-timer-destroy, g-timer-start, g-timer-stop,
	g-timer-reset, g-timer-elapsed;
  export g-strdelimit, g-strtod, g-strerror, g-strsignal,
	g-strcasecmp, g-strncasecmp, g-strdown, g-strup, g-strreverse,
	g-strchug, g-strchomp, g-strdup, g-strndup, g-strnfill, g-strescape,
	g-memdup, g-strsplit, g-strjoinv, g-strfreev;
  export g-get-user-name, g-get-real-name, g-get-home-dir,
	g-get-tmp-dir, g-get-prgname, g-set-prgname;
  export g-parse-debug-string, g-basename, g-path-is-absolute,
	g-path-skip-root, g-dirname, g-get-current-dir, g-getenv;
  export g-atexit;
  export g-bit-nth-lsf, g-bit-nth-msf, g-bit-storage,
	g-string-chunk-new, g-string-chunk-free, g-string-chunk-insert,
	g-string-chunk-insert-const;
  export g-string-new, g-string-sized-new, g-string-free,
	g-string-assign, g-string-truncate, g-string-append,
	g-string-append-c, g-string-prepend, g-string-prepend-c,
	g-string-insert, g-string-insert-c, g-string-erase, g-string-down,
	g-string-up;
  export g-array-new, g-array-free, g-array-append-vals,
	g-array-prepend-vals, g-array-insert-vals, g-array-set-size,
	g-array-remove-index, g-array-remove-index-fast, g-ptr-array-new,
	g-ptr-array-free, g-ptr-array-set-size, g-ptr-array-remove-index,
	g-ptr-array-remove-index-fast, g-ptr-array-remove,
	g-ptr-array-remove-fast, g-ptr-array-add, g-byte-array-new,
	g-byte-array-free, g-byte-array-append, g-byte-array-prepend,
	g-byte-array-set-size, g-byte-array-remove-index,
	g-byte-array-remove-index-fast;
  export g-str-equal, g-str-hash, g-int-equal, g-int-hash,
	g-direct-hash, g-direct-equal;
  export g-quark-try-string, g-quark-from-static-string,
	g-quark-from-string, g-quark-to-string;
  export g-datalist-init, g-datalist-clear, g-datalist-id-get-data,
	g-datalist-id-set-data-full, g-datalist-id-remove-no-notify,
	g-datalist-foreach, g-dataset-destroy, g-dataset-id-get-data,
	g-dataset-id-set-data-full, g-dataset-id-remove-no-notify,
	g-dataset-foreach, $G-ERR-UNKNOWN, $G-ERR-UNEXP-EOF,
	$G-ERR-UNEXP-EOF-IN-STRING, $G-ERR-UNEXP-EOF-IN-COMMENT,
	$G-ERR-NON-DIGIT-IN-CONST, $G-ERR-DIGIT-RADIX, $G-ERR-FLOAT-RADIX,
	$G-ERR-FLOAT-MALFORMED, <GErrorType*>, <GErrorType**>, <GErrorType>,
	$G-TOKEN-EOF, $G-TOKEN-LEFT-PAREN, $G-TOKEN-RIGHT-PAREN,
	$G-TOKEN-LEFT-CURLY, $G-TOKEN-RIGHT-CURLY, $G-TOKEN-LEFT-BRACE,
	$G-TOKEN-RIGHT-BRACE, $G-TOKEN-EQUAL-SIGN, $G-TOKEN-COMMA,
	$G-TOKEN-NONE, $G-TOKEN-ERROR, $G-TOKEN-CHAR, $G-TOKEN-BINARY,
	$G-TOKEN-OCTAL, $G-TOKEN-INT, $G-TOKEN-HEX, $G-TOKEN-FLOAT,
	$G-TOKEN-STRING, $G-TOKEN-SYMBOL, $G-TOKEN-IDENTIFIER,
	$G-TOKEN-IDENTIFIER-NULL, $G-TOKEN-COMMENT-SINGLE,
	$G-TOKEN-COMMENT-MULTI, $G-TOKEN-LAST, <GTokenType*>, <GTokenType**>,
	<GTokenType>, v-symbol-value, v-symbol-value-setter,
	v-identifier-value, v-identifier-value-setter, v-binary-value,
	v-binary-value-setter, v-octal-value, v-octal-value-setter,
	v-int-value, v-int-value-setter, v-float-value, v-float-value-setter,
	v-hex-value, v-hex-value-setter, v-string-value,
	v-string-value-setter, v-comment-value, v-comment-value-setter,
	v-char-value, v-char-value-setter, v-error-value,
	v-error-value-setter, <_GTokenValue>, cset-skip-characters-value,
	cset-skip-characters-value-setter, cset-identifier-first-value,
	cset-identifier-first-value-setter, cset-identifier-nth-value,
	cset-identifier-nth-value-setter, cpair-comment-single-value,
	cpair-comment-single-value-setter, case-sensitive-value,
	case-sensitive-value-setter, skip-comment-multi-value,
	skip-comment-multi-value-setter, skip-comment-single-value,
	skip-comment-single-value-setter, scan-comment-multi-value,
	scan-comment-multi-value-setter, scan-identifier-value,
	scan-identifier-value-setter, scan-identifier-1char-value,
	scan-identifier-1char-value-setter, scan-identifier-NULL-value,
	scan-identifier-NULL-value-setter, scan-symbols-value,
	scan-symbols-value-setter, scan-binary-value,
	scan-binary-value-setter, scan-octal-value, scan-octal-value-setter,
	scan-float-value, scan-float-value-setter, scan-hex-value,
	scan-hex-value-setter, scan-hex-dollar-value,
	scan-hex-dollar-value-setter, scan-string-sq-value,
	scan-string-sq-value-setter, scan-string-dq-value,
	scan-string-dq-value-setter, numbers-2-int-value,
	numbers-2-int-value-setter, int-2-float-value,
	int-2-float-value-setter, identifier-2-string-value,
	identifier-2-string-value-setter, char-2-token-value,
	char-2-token-value-setter, symbol-2-token-value,
	symbol-2-token-value-setter, scope-0-fallback-value,
	scope-0-fallback-value-setter, <_GScannerConfig>, <_GScannerConfig*>,
	user-data-value, user-data-value-setter, max-parse-errors-value,
	max-parse-errors-value-setter, parse-errors-value,
	parse-errors-value-setter, input-name-value, input-name-value-setter,
	derived-data-value, derived-data-value-setter, config-value,
	config-value-setter, token-value, token-value-setter, value-value,
	value-value-setter, line-value, line-value-setter, position-value,
	position-value-setter, next-token-value, next-token-value-setter,
	next-value-value, next-value-value-setter, next-line-value,
	next-line-value-setter, next-position-value,
	next-position-value-setter, symbol-table-value,
	symbol-table-value-setter, input-fd-value, input-fd-value-setter,
	text-value, text-value-setter, text-end-value, text-end-value-setter,
	buffer-value, buffer-value-setter, scope-id-value,
	scope-id-value-setter, msg-handler-value, msg-handler-value-setter,
	<_GScanner>, <_GScanner*>, g-scanner-new, g-scanner-destroy,
	g-scanner-input-file, g-scanner-sync-file-offset,
	g-scanner-input-text, g-scanner-get-next-token,
	g-scanner-peek-next-token, g-scanner-cur-token, g-scanner-cur-value,
	g-scanner-cur-line, g-scanner-cur-position, g-scanner-eof,
	g-scanner-set-scope, g-scanner-scope-add-symbol,
	g-scanner-scope-remove-symbol, g-scanner-scope-lookup-symbol,
	g-scanner-scope-foreach-symbol, g-scanner-lookup-symbol,
	g-scanner-freeze-symbol-table, g-scanner-thaw-symbol-table,
	g-scanner-unexp-token, g-scanner-stat-mode, items-value,
	items-value-setter, func-value, func-value-setter, prefix-value,
	prefix-value-setter, cache-value, cache-value-setter, <_GCompletion>,
	<_GCompletion*>, g-completion-new, g-completion-add-items,
	g-completion-remove-items, g-completion-clear-items,
	g-completion-complete, g-completion-free;
  export <GDateYear*>, <GDateYear**>, <GDateYear>, <GDateDay*>,
	<GDateDay**>, <GDateDay>, <GDate*>, <GDate**>, <GDate>, $G-DATE-DAY,
	$G-DATE-MONTH, $G-DATE-YEAR, <GDateDMY*>, <GDateDMY**>, <GDateDMY>,
	$G-DATE-BAD-WEEKDAY, $G-DATE-MONDAY, $G-DATE-TUESDAY,
	$G-DATE-WEDNESDAY, $G-DATE-THURSDAY, $G-DATE-FRIDAY,
	$G-DATE-SATURDAY, $G-DATE-SUNDAY, <GDateWeekday*>, <GDateWeekday**>,
	<GDateWeekday>, $G-DATE-BAD-MONTH, $G-DATE-JANUARY, $G-DATE-FEBRUARY,
	$G-DATE-MARCH, $G-DATE-APRIL, $G-DATE-MAY, $G-DATE-JUNE,
	$G-DATE-JULY, $G-DATE-AUGUST, $G-DATE-SEPTEMBER, $G-DATE-OCTOBER,
	$G-DATE-NOVEMBER, $G-DATE-DECEMBER, <GDateMonth*>, <GDateMonth**>,
	<GDateMonth>, $G-DATE-BAD-JULIAN, $G-DATE-BAD-DAY, $G-DATE-BAD-YEAR,
	julian-days-value, julian-days-value-setter, julian-value,
	julian-value-setter, dmy-value, dmy-value-setter, day-value,
	day-value-setter, month-value, month-value-setter, year-value,
	year-value-setter, <_GDate>, <_GDate*>, g-date-new, g-date-new-dmy,
	g-date-new-julian, g-date-free, g-date-valid, g-date-valid-day,
	g-date-valid-month, g-date-valid-year, g-date-valid-weekday,
	g-date-valid-julian, g-date-valid-dmy, g-date-weekday, g-date-month,
	g-date-year, g-date-day, g-date-julian, g-date-day-of-year,
	g-date-monday-week-of-year, g-date-sunday-week-of-year, g-date-clear,
	g-date-set-parse, g-date-set-time, g-date-set-month, g-date-set-day,
	g-date-set-year, g-date-set-dmy, g-date-set-julian,
	g-date-is-first-of-month, g-date-is-last-of-month, g-date-add-days,
	g-date-subtract-days, g-date-add-months, g-date-subtract-months,
	g-date-add-years, g-date-subtract-years, g-date-is-leap-year,
	g-date-days-in-month, g-date-monday-weeks-in-year,
	g-date-sunday-weeks-in-year, g-date-compare, g-date-strftime;
  export g-relation-new, g-relation-destroy, g-relation-index,
	g-relation-delete, g-relation-select, g-relation-count,
	g-relation-print, g-tuples-destroy, g-tuples-index;
  export g-spaced-primes-closest;
  export <GIOFuncs*>, <GIOFuncs**>, <GIOFuncs>, $G-IO-ERROR-NONE,
	$G-IO-ERROR-AGAIN, $G-IO-ERROR-INVAL, $G-IO-ERROR-UNKNOWN,
	<GIOError*>, <GIOError**>, <GIOError>, $G-SEEK-CUR, $G-SEEK-SET,
	$G-SEEK-END, <GSeekType*>, <GSeekType**>, <GSeekType>, $G-IO-IN,
	$G-IO-OUT, $G-IO-PRI, $G-IO-ERR, $G-IO-HUP, $G-IO-NVAL,
	<GIOCondition*>, <GIOCondition**>, <GIOCondition>,
	channel-flags-value, channel-flags-value-setter, ref-count-value,
	ref-count-value-setter, funcs-value, funcs-value-setter,
	<_GIOChannel>, <_GIOChannel*>;
  export <GIOFunc*>, <GIOFunc**>, <GIOFunc>, io-read-value,
	io-read-value-setter, io-write-value, io-write-value-setter,
	io-seek-value, io-seek-value-setter, io-close-value,
	io-close-value-setter, io-add-watch-value, io-add-watch-value-setter,
	io-free-value, io-free-value-setter, <_GIOFuncs>, <_GIOFuncs*>,
	g-io-channel-init, g-io-channel-ref, g-io-channel-unref,
	g-io-channel-read, g-io-channel-write, g-io-channel-seek,
	g-io-channel-close, g-io-add-watch-full, g-io-add-watch;
  export <GTimeVal*>, <GTimeVal**>, <GTimeVal>, <GSourceFuncs*>,
	<GSourceFuncs**>, <GSourceFuncs>, tv-sec-value, tv-sec-value-setter,
	tv-usec-value, tv-usec-value-setter, <_GTimeVal>, <_GTimeVal*>,
	prepare-value, prepare-value-setter, check-value, check-value-setter,
	dispatch-value, dispatch-value-setter, destroy-value,
	destroy-value-setter, <_GSourceFuncs>, <_GSourceFuncs*>,
	$G-PRIORITY-HIGH, $G-PRIORITY-DEFAULT, $G-PRIORITY-HIGH-IDLE,
	$G-PRIORITY-DEFAULT-IDLE, $G-PRIORITY-LOW, <GSourceFunc*>,
	<GSourceFunc**>, <GSourceFunc>, g-source-add, g-source-remove,
	g-source-remove-by-user-data, g-source-remove-by-source-data,
	g-source-remove-by-funcs-user-data, g-get-current-time, g-main-new,
	g-main-run, g-main-quit, g-main-destroy, g-main-is-running,
	g-main-iteration, g-main-pending, g-timeout-add-full, g-timeout-add,
	g-idle-add, g-idle-add-full, g-idle-remove-by-data;
  export <GPollFD*>, <GPollFD**>, <GPollFD>, <GPollFunc*>,
	<GPollFunc**>, <GPollFunc>, fd-value, fd-value-setter, events-value,
	events-value-setter, revents-value, revents-value-setter, <_GPollFD>,
	<_GPollFD*>, g-main-add-poll, g-main-remove-poll,
	g-main-set-poll-func, g-io-channel-unix-new,
	g-io-channel-unix-get-fd, $G-WIN32-MSG-HANDLE,
	g-main-poll-win32-msg-add, g-io-channel-win32-new-messages,
	g-io-channel-win32-new-pipe,
	g-io-channel-win32-new-pipe-with-wakeups,
	g-io-channel-win32-pipe-request-wakeups,
	g-io-channel-win32-pipe-readable, g-io-channel-win32-get-fd,
	g-io-channel-win32-new-stream-socket, $MAXPATHLEN, <pid-t*>,
	<pid-t**>, <pid-t>, $NAME-MAX, dir-name-value, dir-name-value-setter,
	just-opened-value, just-opened-value-setter, find-file-handle-value,
	find-file-handle-value-setter, find-file-data-value,
	find-file-data-value-setter, <_DIR>, <_DIR*>, <DIR*>, <DIR**>, <DIR>,
	d-name-array, d-name-array-setter, d-name-value, <_dirent>,
	<_dirent*>, <dirent*>, <dirent**>, <dirent>, gwin-ftruncate,
	gwin-opendir, gwin-readdir, gwin-rewinddir, gwin-closedir,
	<GStaticPrivate*>, <GStaticPrivate**>, <GStaticPrivate>,
	<GThreadFunctions*>, <GThreadFunctions**>, <GThreadFunctions>,
	mutex-new-value, mutex-new-value-setter, mutex-lock-value,
	mutex-lock-value-setter, mutex-trylock-value,
	mutex-trylock-value-setter, mutex-unlock-value,
	mutex-unlock-value-setter, mutex-free-value, mutex-free-value-setter,
	cond-new-value, cond-new-value-setter, cond-signal-value,
	cond-signal-value-setter, cond-broadcast-value,
	cond-broadcast-value-setter, cond-wait-value, cond-wait-value-setter,
	cond-timed-wait-value, cond-timed-wait-value-setter, cond-free-value,
	cond-free-value-setter, private-new-value, private-new-value-setter,
	private-get-value, private-get-value-setter, private-set-value,
	private-set-value-setter, <_GThreadFunctions>, <_GThreadFunctions*>,
	g-thread-init, g-static-mutex-get-mutex-impl, index-value,
	index-value-setter, <_GStaticPrivate>, <_GStaticPrivate*>,
	g-static-private-get, g-static-private-set, glib-dummy-decl;

  // from "glibconfig.h":
  export <gint8*>, <gint8**>, <gint8>, <guint8*>, <guint8**>,
	<guint8>, <gint16*>, <gint16**>, <gint16>, <guint16*>, <guint16**>,
	<guint16>, <gint32*>, <gint32**>, <gint32>, <guint32*>, <guint32**>,
	<guint32>, $G-HAVE-GINT64, $G-HAVE-ALLOCA, $GLIB-MAJOR-VERSION,
	$GLIB-MINOR-VERSION, $GLIB-MICRO-VERSION, $G-HAVE---INLINE;
  export <GStaticMutex*>, <GStaticMutex**>, <GStaticMutex>,
	runtime-mutex-value, runtime-mutex-value-setter, pad-array,
	pad-array-setter, pad-value, dummy-double-value,
	dummy-double-value-setter, dummy-pointer-value,
	dummy-pointer-value-setter, dummy-long-value,
	dummy-long-value-setter, pad-array, pad-array-setter, pad-value,
	dummy-double-value, dummy-double-value-setter, dummy-pointer-value,
	dummy-pointer-value-setter, dummy-long-value,
	dummy-long-value-setter, aligned-pad-u-value,
	aligned-pad-u-value-setter, <_GStaticMutex>, <_GStaticMutex*>,
	$G-BYTE-ORDER, $G-HAVE-WCHAR-H, $G-HAVE-WCTYPE-H, $WIN32,
	$NATIVE-WIN32;

  // from "gmodule.h":
  export $G-MODULE-BIND-LAZY, $G-MODULE-BIND-MASK, <GModuleFlags*>,
	<GModuleFlags**>, <GModuleFlags>;
  export <GModuleCheckInit*>, <GModuleCheckInit**>,
	<GModuleCheckInit>, <GModuleUnload*>, <GModuleUnload**>,
	<GModuleUnload>, g-module-supported, g-module-open, g-module-close,
	g-module-make-resident, g-module-error, g-module-symbol,
	g-module-name;
  export g-module-build-path;

  // from "gmoduleconf.h":
  export $G-MODULE-IMPL-NONE, $G-MODULE-IMPL-DL, $G-MODULE-IMPL-DLD,
	$G-MODULE-IMPL-WIN32, $G-MODULE-IMPL;

  // Useful extensions from first.dylan
  export \open-accessor-definer;

  // Protocols from first.dylan
  export area-value, area-value-setter,
         background-value, background-value-setter,
         bg-gc-value, bg-gc-value-setter,
	 bin-value, bin-value-setter,
	 button-value, button-value-setter,
	 children-value, children-value-setter,
	 colormap-value, colormap-value-setter,
	 configure-event-value, configure-event-value-setter,
	 container-value, container-value-setter,
	 cursor-value, cursor-value-setter,
	 data-value, data-value-setter,
	 depth-value, depth-value-setter,
	 destroy-value, destroy-value-setter,
         fg-gc-value, fg-gc-value-setter,
	 fill-value, fill-value-setter,
	 flags-value, flags-value-setter,
	 focus-value, focus-value-setter,
	 font-value, font-value-setter,
	 foreground-value, foreground-value-setter,
	 func-value, func-value-setter,
	 height-value, height-value-setter,
	 key-value, key-value-setter,
         index-value, index-value-setter,
	 length-value, length-value-setter,
	 max-width-value, max-width-value-setter,
	 min-width-value, min-width-value-setter,
	 motion-value, motion-value-setter,
	 name-value, name-value-setter,
	 parent-value, parent-value-setter,
	 parent-class-value, parent-class-value-setter,
	 position-value, position-value-setter,
	 property-value, property-value-setter,
	 ref-count-value, ref-count-value-setter,
	 selection-value, selection-value-setter,
	 seq-id-value, seq-id-value-setter,
	 spacing-value, spacing-value-setter,
	 state-value, state-value-setter,
	 style-value, style-value-setter,
	 target-value, target-value-setter,
	 text-value, text-value-setter,
         text-end-value, text-end-value-setter,
	 title-value, title-value-setter,
	 type-value, type-value-setter,
	 user-data-value, user-data-value-setter,
	 value-value, value-value-setter,
	 widget-value, widget-value-setter,
	 width-value, width-value-setter,
	 window-value, window-value-setter,
	 wmclass-class-value, wmclass-class-value-setter,
	 wmclass-name-value, wmclass-name-value-setter,
	 x-value, x-value-setter,
	 y-value, y-value-setter;
  
  // Hacks from special.dylan
  export <C-string**>,
         <gchar***>;

  export $GLIB-SYSDEF-POLLIN,
         $GLIB-SYSDEF-POLLOUT,
         $GLIB-SYSDEF-POLLPRI,
         $GLIB-SYSDEF-POLLERR,
         $GLIB-SYSDEF-POLLHUP,
         $GLIB-SYSDEF-POLLNVAL;

  export <GAllocator*>, <GAllocator**>,
         <GCache*>, <GCache**>,
         <GCond*>, <GCond**>,
         <GData*>, <GData**>,
         <GHashTable*>, <GHashTable**>,
         <GMainLoop*>, <GMainLoop**>,
         <GMemChunk*>, <GMemChunk**>,
         <GModule*>, <GModule**>,
         <GMutex*>, <GMutex**>,
         <GPrivate*>, <GPrivate**>,
         <GRelation*>, <GRelation**>,
         <GStringChunk*>, <GStringChunk**>,
         <GTimer*>, <GTimer**>,
         <GTree*>, <GTree**>;
end module Glib;