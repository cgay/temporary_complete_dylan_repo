Module: dylan-user

define library regular-expressions-test-suite
  use common-dylan;
  use io,
    import: {
      streams
    };
  use regular-expressions;
  use system,
    import: {
      file-system,
      locators,
      operating-system
    };
  use strings;
  use testworks;
  export
    regular-expressions-test-suite;
end library regular-expressions-test-suite;

define module regular-expressions-test-suite
  use common-dylan,
    exclude: {
      split
    };
  use regular-expressions;
  use file-system;
  use locators,
    import: {
      <directory-locator>,
      <file-locator>,
      subdirectory-locator
    };
  use operating-system,
    import: {
      environment-variable
    };
  use testworks;
  use streams;
  use strings,
    import: {
      trim
    };
  export regular-expressions-test-suite;
end module regular-expressions-test-suite;


