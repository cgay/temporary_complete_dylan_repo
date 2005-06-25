module: world

define abstract class <agent> (<object>)
  slot agent-player :: <player>;
  slot wanted-name = "DyBot";
end class <agent>;

define open abstract class <cop> (<agent>)
  slot initial-transport = "cop-foot";
end class <cop>;

define open abstract class <robber> (<agent>)
end class <robber>;

define open generic choose-move(agent :: <agent>, world :: <world>);

define open generic make-informs(cop :: <cop>, world :: <world>) => (informs);

define method make-informs(cop :: <cop>, world :: <world>) => (informs);
  #()
end method make-informs;

define open generic perceive-informs(informs, cop :: <cop>, world :: <world>);

define method perceive-informs(informs, cop :: <cop>, world :: <world>);
end method perceive-informs;

define open generic make-plan(cop :: <cop>, world :: <world>) => (plan);

define method make-plan(cop :: <cop>, world :: <world>) => (informs);
  #()
end method make-plan;

define open generic perceive-plans(plans, cop :: <cop>, world :: <world>);

define method perceive-plans(plans, cop :: <cop>, world :: <world>);
end method perceive-plans;

define open generic make-vote(cop :: <cop>, world :: <world>) => (vote);

define method make-vote(cop :: <cop>, world :: <world>) => (vote);
  choose(method(x)
             (x.player-type = "cop-foot") | (x.player-type = "cop-car")
         end, world.world-players)
end method make-vote;

define open generic perceive-vote(vote, cop :: <cop>, world :: <world>);

define method perceive-vote(vote, cop :: <cop>, world :: <world>);
end method perceive-vote;

define open generic drive-agent(agent :: <agent>,
                                input-stream :: <stream>,
                                output-stream :: <stream>);

define method drive-agent(agent :: <robber>,
                          input-stream :: <stream>,
                          output-stream :: <stream>)
  format(output-stream, "reg: %s robber\n", agent.wanted-name);
  force-output(output-stream);
  let skelet = read-world-skeleton(input-stream);
  block()
    while (#t)
      let world = read-world(input-stream, skelet);
      agent.agent-player := find-player(skelet.my-name, world);
      //dbg("DRIVE-AGENT: %s\n", node-name(choose-move(agent, world)));
      let move = choose-move(agent, world);
      print(move);
      force-output(output-stream);
    end while;
  exception (condition :: <parse-error>)
  end;
end method drive-agent;

define method drive-agent(agent :: <cop>,
                          input-stream :: <stream>,
                          output-stream :: <stream>)
  send("reg: %s %s\n", agent.wanted-name, agent.initial-transport);
  let skelet = read-world-skeleton(*standard-input*);

  block()
    while (#t)
      let world = read-world(*standard-input*, skelet);
      agent.agent-player := find-player(skelet.my-name, world);

      send("inf\\\n");
      do(print, make-informs(agent, world));
      send("inf/\n");

      perceive-informs(read-from-message-inform(input-stream),
                       agent, world);

      send("plan\\\n");
      do(print, make-plan(agent, world));
      send("plan/\n");

      perceive-plans(read-from-message-plan(input-stream),
                     agent, world);

      send("vote\\\n");
      do(method(x) send("vote: %s\n", x.player-name) end,
         make-vote(agent, world));
      send("vote/\n");
      
      perceive-vote(read-vote-tally(input-stream), agent, world);

      print(choose-move(agent, world));
    end while;
  exception (condition :: <parse-error>)
  end;
end method drive-agent;

define method print (inform :: <inform>)
  if (inform.plan-world < 200) 
    send("inf: %s %s %s %d %d\n", inform.plan-bot,
         inform.plan-location.node-name, inform.plan-type,
         inform.plan-world, inform.inform-certainty);
  end if;
end method print;

define method print (plan :: <plan>)
  if (plan.plan-world < 200) 
    send("plan: %s %s %s %d\n", plan.plan-bot,
         plan.plan-location.node-name,
         plan.plan-type, plan.plan-world);
  end if;
end method print;

    
define class <move> (<object>)
  slot target :: <node>, init-keyword: target:;
  slot transport :: <string>, init-keyword: transport:;
end class;

define method print (move :: <move>)
  send("mov: %s %s\n",
       move.target.node-name,
       move.transport);
end method;

define method generate-moves (player :: <player>)
  => (move)
  let move = make(<move>,
                  target: player.player-location,
                  transport: player.player-type);
  generate-moves(move);

end method;

define method generate-moves(move :: <move>)
  let options = make(<stretchy-vector>);

  local method add-to-options (list, transport)
          for (tar in move.target.list)
            add!(options, make(<move>,
                               target: tar,
                               transport: transport));
          end;
        end method;

  if (move.transport = "robber")
    add-to-options(moves-by-foot, "robber");
  else
    if ((move.transport = "cop-foot") |
          (move.target.node-tag = "hq"))
      add-to-options(moves-by-foot, "cop-foot")
    end;
    if ((move.transport = "cop-car") | 
          (move.target.node-tag = "hq"))
      add-to-options(moves-by-car, "cop-car")
    end;
  end if;

  //for (ele in options)
  //  dbg("GENMOVE: %= %=\n", ele.target.node-name, ele.transport);
  //end;

  options;

end method;

define method generate-plan(world :: <world>,
                            player :: <player>,
                            move :: <move>)
  => (plan :: <plan>)
  make(<plan>,
       bot: player.player-name,
       location: move.target,
       type: move.transport,
       world: world.world-number + 1);
end method;

define function distance
    (player :: <player>,
     target-node :: <node>,
     #key source :: <move>
       = make(<move>,
              target: player.player-location,
              transport: player.player-type)) => (rank, shortest-path)

  let rank :: <vector> =
    make(<vector>, size: maximum-node-id(), fill: maximum-node-id());
  rank[source.target.node-id] := 0;
  let shortest-path :: <vector> =
    make(<vector>, size: maximum-node-id(), fill: #());

  let todo-nodes = make(<deque>);

  local method search (start)
          block (return)
            for (move in generate-moves(start))
              if (rank[move.target.node-id] > rank[start.target.node-id])
                rank[move.target.node-id] := rank[start.target.node-id] + 1;
                shortest-path[move.target.node-id] :=
                  add(shortest-path[start.target.node-id], move);
                push-last(todo-nodes, move);
              end if;
              if (move.target = target-node)
                return(move.target.node-id);
              end if;
            end for;
            if (todo-nodes.size = 0)
              error("Graph not connected");
            end if;
            search(todo-nodes.pop);
          end;
        end method;

  let result = search(source);
  /*dbg("LOC: %s TARGET: %s\n", player.player-location.node-name,
      target-node.node-name);
  for (i from 0 below maximum-node-id())
    if (size(shortest-path[i]) > 0)
      dbg("SP TO %d, distance: %d  ", i, rank[i]);
      for (j in shortest-path[i])
        dbg("%s ", j.target.node-name);
      end for;
      dbg("\n");
    end if;
  end for;*/
  values(rank[result], reverse(shortest-path[result]));
end;
