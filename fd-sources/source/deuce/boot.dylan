Module:       deuce-internals
Synopsis:     The Deuce editor
Author:       Scott McKay
Copyright:    Original Code is Copyright (c) 1996-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Bootstrapping

// For buffer bootstrapping...
define variable $null-line :: <text-line>
    = make(<text-line>, contents: "");
define variable $null-bp   :: <simple-bp>
    = make-bp($null-line, 0);

// For frame bootstrapping...
define variable $null-editor :: <simple-editor>
    = make(<simple-editor>);

// For window bootstrapping...
define variable $null-editor-frame :: <simple-editor-frame>
    = make(<simple-editor-frame>, editor: $null-editor);
