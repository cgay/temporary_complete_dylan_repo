module: progress-indicator

define abstract class <progress-indicator> (<object>)
  constant slot total :: <integer>, required-init-keyword: total:;
  slot done :: <integer> = 0;
#if (~mindy)
  slot last-time-flushed :: <integer> = 0;
#endif
end class <progress-indicator>;

define method increment-progress(indicator :: <progress-indicator>) => ()
  indicator.done := indicator.done + 1;
end method increment-progress;

define generic report-progress(indicator :: <progress-indicator>) => ();

define method increment-and-report-progress
    (indicator :: <progress-indicator>) => ();
  increment-progress(indicator);
#if (mindy)
  report-progress(indicator);
#else
  let now :: <integer> = get-time-of-day();
  if (now ~= indicator.last-time-flushed)
    report-progress(indicator);
    indicator.last-time-flushed := now;
  end;
#endif
end method increment-and-report-progress;

define method increment-and-report-progress(f == #f) => ();
  // nothing
end method increment-and-report-progress;

define class <stream-progress-indicator> (<progress-indicator>)
  slot output-stream :: <stream>, required-init-keyword: stream:;
end class <stream-progress-indicator>;

define class <draw-dots-progress-indicator> (<stream-progress-indicator>)
  slot last-reported-progress :: <integer> = 0;
end class <draw-dots-progress-indicator>;

define method report-progress(indicator :: <draw-dots-progress-indicator>) => ()
  let stream = indicator.output-stream;
  for(i from indicator.last-reported-progress below indicator.done)
    let column = stream.current-column;
    if (column & column > 75)
      format(stream, "\n");
    end if;
    format(stream, ".");
  end for;
  indicator.last-reported-progress := indicator.done;
  force-output(stream);
end method report-progress;

define class <n-of-k-progress-indicator> (<stream-progress-indicator>)
end class <n-of-k-progress-indicator>;

define method report-progress(indicator :: <n-of-k-progress-indicator>) => ()
  let stream = indicator.output-stream;
  format(stream, "%=/%= tlfs processed.\r", indicator.done, indicator.total);
  force-output(stream);
end method report-progress;


    