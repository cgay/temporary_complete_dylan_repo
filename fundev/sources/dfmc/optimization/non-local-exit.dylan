module: dfmc-optimization
Author: Jonathan Bachrach
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// define compilation-pass analyze-non-local-exits,
//   disabled?: #t,
//   visit: functions,
//   after: try-inlining,
//   triggered-by: try-inlining,
//   trigger: analyze-calls;

define method analyze-non-local-exits (lambda :: <&lambda>) => ()
  let changed? = #f;
  for (entry in lambda.environment.entries)
    changed? := analyze-entry(entry);
  end for;
  changed?
end method;

define method analyze-entry (entry :: <entry-state>) => ()
  for (exit in entry.exits)
  end for;
  #f
end method;
