test {
  let str = "ay"
  let ctx = @yaml.ParseContext::make(str)
  let yaml = @yaml.lex_value(ctx)
  println(yaml)
   //inspect!(@strconv.parse_int!("0x1"), content="1")
}