Module:       build-system
Author:       Peter S. Housel
Copyright:    Original Code is Copyright 2004 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define method jam-read-mkf
    (jam :: <jam-state>, file :: <file-locator>)
 => ();
  let variables = read-file-header(file);
  let image = concatenate(element(variables, #"library"),
                          element(variables, #"executable", default: #()));

  // DylanLibrary image : version ;
  let version
    = concatenate(element(variables, #"major-version", default: #()),
                  element(variables, #"minor-version", default: #()));
  jam-invoke-rule(jam, "DylanLibrary", image, version);

  // DylanLibraryLinkerOptions image : options ;
  // DylanLibraryBaseAddress image : address ;
  // DylanLibraryCLibraries image : libraries ;
  // DylanLibraryCObjects image : objects ;
  // DylanLibraryCSources image : sources ;
  // DylanLibraryCHeaders image : headers ;
  // DylanLibraryRCFiles image : rcfiles ;
  // DylanLibraryJamIncludes image : includes ;
  let rule-specs
    = #[#["DylanLibraryFiles", #"files", #f],
        #["DylanLibraryBaseAddress", #"base-address", #f],
        #["DylanLibraryLinkerOptions", #"linker-options", #t],
        #["DylanLibraryCLibraries", #"c-libraries", #t],
        #["DylanLibraryCObjects", #"c-objects", #f],
        #["DylanLibraryCSources", #"c-source-files", #f],
        #["DylanLibraryCHeaders", #"c-header-files", #f],
        #["DylanLibraryRCFiles", #"rc-files", #f],
        #["DylanLibraryJamIncludes", #"jam-includes", #f]];
  for(spec in rule-specs)
    let value = element(variables, spec[1], default: #());
    let expanded = if (spec[2]) jam-expand-list(jam, value) else value end;
    unless (expanded.empty?)
      jam-invoke-rule(jam, spec[0], image, expanded);
    end unless;
  end for;

  // DylanLibraryUses image : library : dir ;
  let used-projects = element(variables, #"used-projects", default: #());
  for (i from 0 below used-projects.size by 3)
    jam-invoke-rule(jam, "DylanLibraryUses",
                    image,
                    vector(used-projects[i]),
                    vector(used-projects[i + 2]));
  end for;
end method;



define variable *cached-build-script* :: false-or(<file-locator>) = #f;
define variable *cached-jam-state* :: false-or(<jam-state>) = #f;

define function make-jam-state
    (build-script :: <file-locator>,
     #key progress-callback :: <function> = ignore)
 => (jam :: <jam-state>);
  // ---*** Need to ensure that the build-script hasn't been modified,
  //        and that the working directory hasn't changed, and that
  //        SYSTEM_ROOT and PERSONAL_ROOT are still valid
  if (build-script = *cached-build-script*
        & *cached-jam-state*)
    jam-state-copy(*cached-jam-state*)
  else
    let state = make(<jam-state>);

    // Useful built-in variables
    jam-variable(state, "OS") := vector(as(<string>, $os-name));
    jam-variable(state, "OSPLAT") := vector(as(<string>, $machine-name));
    
    select($os-name)
      #"win32" =>
        jam-variable(state, "NT") := #["true"];
      #"linux", #"freebsd", #"solaris", #"osf3" =>
        jam-variable(state, "UNIX") := #["true"];
    end select;
    
    jam-variable(state, "JAMDATE")
      := vector(as-iso8601-string(current-date()));
    jam-variable(state, "JAMVERSION") := #["2.5"];

    // Custom built-in functions
    jam-rule(state, "ECHO")
      := jam-rule(state, "Echo")
      := method(jam :: <jam-state>, #rest lol) => (result :: <sequence>);
             if(lol.size > 0)
               for(arg in lol[0])
                 format(*standard-output*, "%s ", arg);
               end for;
               new-line(*standard-output*);
             end if;
             #[]
         end;
    jam-rule(state, "EXIT")
      := jam-rule(state, "Exit")
      := method(jam :: <jam-state>, #rest lol) => (result :: <sequence>);
             if(lol.size > 0)
               for(arg in lol[0])
                 format(*standard-output*, "%s ", arg);
               end for;
               new-line(*standard-output*);
             end if;
             exit-application(1);
             #[]
         end;
    jam-rule(state, "IncludeMKF")
      := method
             (jam :: <jam-state>, includes :: <sequence>)
          => (result :: <sequence>);
           for (target-name in includes)
             let (locator, target) = jam-target-bind(jam, target-name);
             if (file-exists?(locator))
               jam-read-mkf(jam, locator)
             else
               error(make(<file-does-not-exist-error>, locator: locator));
             end if;
           end;
           #[]
         end method;

    jam-variable(state, "SYSTEM_ROOT")
      := vector(as(<string>, $system-install));
    jam-variable(state, "PERSONAL_ROOT")
      := vector(as(<string>, $personal-install | working-directory()));

    jam-read-file(state, build-script);

    *cached-build-script* := build-script;
    *cached-jam-state* := state;
    jam-state-copy(state)
  end if
end function;
