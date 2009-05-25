Module:    Motif
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "ToggleBG.h"; do not edit.

//	RCSfile: ToggleBG.h,v 
//	Revision: 1.12 
//	Date: 93/03/03 16:35:56 
define C-variable xmToggleButtonGadgetClass :: <WidgetClass>
  c-name: "xmToggleButtonGadgetClass";
end;
define C-subtype <XmToggleButtonGadgetClass> ( <C-void*> ) end;
define C-subtype <XmToggleButtonGadget> ( <C-void*> ) end;
define C-subtype <XmToggleButtonGCacheObject> ( <C-void*> ) end;

define inline-only function XmIsToggleButtonGadget (w);
  XtIsSubclass(w, xmToggleButtonGadgetClass())
end;

define inline-only C-function XmToggleButtonGadgetGetState
  parameter w          :: <Widget>;
  result value :: <X-Boolean>;
  c-name: "XmToggleButtonGadgetGetState";
end;

define inline-only C-function XmToggleButtonGadgetSetState
  parameter w          :: <Widget>;
  parameter newstate   :: <X-Boolean>;
  parameter notify     :: <X-Boolean>;
  c-name: "XmToggleButtonGadgetSetState";
end;

define inline-only C-function XmCreateToggleButtonGadget
  parameter parent     :: <Widget>;
  parameter name       :: <C-string>;
  parameter arglist    :: <Arg*>;
  parameter argCount   :: <C-Cardinal>;
  result value :: <Widget>;
  c-name: "XmCreateToggleButtonGadget";
end;
