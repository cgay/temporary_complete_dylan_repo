module: dylan-user

define library debugger
  use dylan;
  use common-dylan;
  use io;
  use melange-support;
  use command-processor;
end library debugger;

define module debugger
  use dylan;
  use extensions, exclude: { \without-bounds-checks};
  use common-dylan, exclude: { \without-bounds-checks};
  use format;
  use format-out;
  use standard-io;
  use streams;
  use magic;
  use introspection;
  use system;
  use melange-support;
  use command-processor;
end module debugger;
