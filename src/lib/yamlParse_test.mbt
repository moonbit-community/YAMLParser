test {
  //let str = "boolean:\n  - TRUE\n  - FALSE\nfloat:\n  - 3.14\nint:\n  - 123\nstring:\n  - \"Hello, world!\"\n  - 'Single-quoted string'\ninheritance:\n  defaults: &default_config\n    timeout: 30\n    retries: 3\n  server1:\n    <<: *default_config\n    host: \"example.com\"\n  server2:\n    <<: *default_config\n    timeout: 60"
  //let str = "boolean:\n  - TRUE\n  - FALSE\nfloat:\n  - 3.14\nint:\n  - 123\nstring:\n  - \"Hello, world!\"\n  - \'Single-quoted string\'\ndate:\n  - 2018-02-17"
  //let str = "boolean:\n  - TRUE\n  - FALSE"
  let str = "inheritance:\n  defaults: &default_config\n    timeout: 30\n    retries: 3\n  server1:\n    <<: *default_config\n    host: \"example.com\"\n    host2: \"example.com\"\n"
  let yaml = @yaml.parse_yaml(str)
  println(yaml)
   //inspect!(@strconv.parse_int!("0x1"), content="1")
}
