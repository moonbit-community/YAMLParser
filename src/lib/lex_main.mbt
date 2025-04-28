let non_ascii_whitespace : YAMLCharClass = YAMLCharClass::of([
  ('\u00A0', '\u00A0'),
  ('\u1680', '\u1680'),
  ('\u2000', '\u200A'),
  ('\u2028', '\u2029'),
  ('\u202F', '\u202F'),
  ('\u205F', '\u205F'),
  ('\u3000', '\u3000'),
  ('\uFEFF', '\uFEFF'),
])

fn lex_value(ctx : ParseContext, pos : Position) -> YamlValue!ParseError{
    for{
        match(read_char(ctx)){
            Some('\t' | '\n' | '\r') => continue

            Some('~') => {
                // NULL
                return YamlValue::Null
            }

            Some('t' | 'T') => {
                // TRUE
                assert_char_escape!(ctx, 'r');
                assert_char_escape!(ctx, 'u');
                assert_char_escape!(ctx, 'e');
                return YamlValue::True
            }

            Some('f' | 'F') => {
                // False
                assert_char_escape!(ctx, 'a');
                assert_char_escape!(ctx, 'l');
                assert_char_escape!(ctx, 's');
                assert_char_escape!(ctx, 'e');
                return YamlValue::False
            }

            Some('0') => {
                // 解析 0 开头的数字，包括科学计数法、小数、二进制、十六进制等
                let n = ctx.lex_zero!(start=ctx.offset - 1)
                return Number(n)
            }

            // 解析数字，可能存在日期，如果是日期，则第五位是 '-'
            Some('1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9') => {
                match(peek_designated_char(ctx, ctx.offset + 4)){
                    Some('-') => {
                        let data = ctx.lex_data!(start=ctx.offset - 1)
                        return String(data)
                    }
                    _ => {
                        let n = ctx.lex_decimal_integer!(start=ctx.offset - 1)
                        return Number(n)
                    }
                }
            }

            // 解析单引号字符串
            Some('\'') => {
                let s = ctx.lex_single_quote_string!()
                return String(s)
            }
            
            // 解析双引号字符串
            Some('"') => {
                let s = ctx.lex_double_quote_string!()
                return String(s)
            }

            Some(c) => {
                if c > '\u{7f}' && non_ascii_whitespace.contains(c) {
                    continue
                }
                invalid_char!(ctx, shift=-1)
            }

            None => raise InvalidEof
        }
    }
}