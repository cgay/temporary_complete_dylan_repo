module: board

define constant <board> = <array>;

define class <state> (<object>)
  slot board :: <board>, required-init-keyword: board:;
  slot robots :: <collection> = #(), init-keyword: robots:;
  slot packages :: <collection> = #(), init-keyword: packages:;
  slot bases :: <collection> = #(), init-keyword: bases:;
end class <state>;

// Terrain types
define abstract functional class <terrain>(<object>)
end;

define macro terrain-definer
  { define terrain ?:name ?ch:expression end }
  =>
  {
   define concrete functional class ?name(<terrain>)
   end;
    
   define sealed domain make(?name.singleton);
   define sealed domain initialize(?name);

   define method print-object(obj :: ?name, stream :: <stream>) => ();
      format(stream, "%c", ?ch);
   end;

  }
end;

define terrain <wall> '#' end;
define terrain <water> '~' end;
define terrain <base> '@' end;
define terrain <space> '.' end;

// Board

define inline function passable?(b :: <board>, p :: <point>)
 => (passable :: <boolean>);
  let ch :: <terrain> = b[p.y, p.x];
  instance?(ch, <space>) | instance?(ch, <base>);
//  let ch :: <character> = b[p.y, p.x];
//  ch == '.' | ch == '@';
end;

define inline function width(b :: <board>) => w :: <coordinate>;
  dimension(b, 0);
end;

define inline function height(b :: <board>) => w :: <coordinate>;
  dimension(b, 1);
end;

/*
define method print-object(board :: <board>, stream :: <stream>)
 => ();
  format(stream, "board {\n");
  for (y from 0 below board.width)
    for (x from 0 below board.width)
      print-object(board[y,x], stream);
    end;
    format(stream, "\n");
  end;
  format(stream, "U=%=, size=%=, color=%}");
end method print-object;
*/

// store objects line by line

define method add-robot (state :: <state>, robot :: <robot>) => <state>;
  // Add a robot to the <state>'s list of robots. If a robot with the
  // same id is present, replace it. If not, add it.
  //
  let robots* = 
    block(return)
      iterate loop (lst = state.robots)
        if (lst.empty?)
          return(pair(robot, state.robots))
        else
          if (lst.head.id = robot.id)
            pair(robot, lst.tail)
          else
            pair(lst.head, lst.tail.loop)
          end if;
        end if;
      end iterate;
    end block;
  make(<state>, board: state.board, robots: robots*, packages: state.packages);
end method add-robot;

/* Package functions: */
define method add-package (state :: <state>, package :: <package>) => <state>;
  // Add a package to the <state>'s list of robots. If a package with the
  // same id is present, replace it. If not, add it.
  //
  let packages* = 
    block(return)
      iterate loop (lst = state.packages)
        if (lst.empty?)
          return(pair(package, state.packages))
        else
          if (lst.head.id = package.id)
            pair(package, lst.tail)
          else
            pair(lst.head, lst.tail.loop)
          end if;
        end if;
      end iterate;
    end block;
  make(<state>, board: state.board, robots: state.robots, packages: packages*);
end method add-package;

define function packages-at(state :: <state>, p :: <point>)
 => (v :: <vector>);
  choose-by(curry(\=, p), map(location, state.packages), state.packages);
end function packages-at;

define function free-packages(s :: <state>)
 => (v :: <vector>);
  choose-by(curry(\=, #f), map(carrier, s.packages), s.packages);
end function free-packages;

define method as(class == <character>, obj :: <character>)
 => obj :: <byte-character>;
  obj
end;

define function terrain-from-character(c :: <character>)
 => terra :: <terrain>;
  select(c)
    '.' => <space>.make;
    '#' => <wall>.make;
    '~' => <water>.make;
    '@' => <base>.make;
  end select;
end function terrain-from-character;

define function send-board(s :: <stream>, board :: <board>)
 => ();
  do(curry(write-line, s),
     map(method (line)
           map-as(<string>, curry(as, <character>), line)
         end,
         board));
end;

define function receive-board(s :: <stream>, board :: <board>)
 => ();
//  let line = s.read-line;
let landscape =  #("..@...."
  "......."
  "##.~~~~"
  "...~~~~"
  ".......");

  board
    := map-as(limited(<vector>, of: <array>),
              curry(map-as, <array>, terrain-from-character),
              landscape);


end;


