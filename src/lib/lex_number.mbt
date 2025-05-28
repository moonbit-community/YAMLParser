fn ParseContext::lex_decimal_integer(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  for {
    match read_char(ctx) {
      Some('.') => return ctx.lex_decimal_point!(start~)
      Some('e' | 'E') => return ctx.lex_decimal_exponent!(start~)
      Some(c) => {
        if ((c >= '0' && c <= '9') || c == '_') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end!(start, ctx.offset)
      }
      None => return ctx.lex_number_end!(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_decimal_point(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  match read_char(ctx) {
    Some(c) =>
      if ((c >= '0' && c <= '9') || c == '_') {
        ctx.lex_decimal_fraction!(start~)
      } else {
        invalid_char!(ctx, shift = -1)
      }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_fraction(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  for {
    match read_char(ctx) {
      Some('e' | 'E') => return ctx.lex_decimal_exponent!(start~)
      Some(c) => {
        if c >= '0' && c <= '9' {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end!(start, ctx.offset)
      }
      None => return ctx.lex_number_end!(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_decimal_exponent(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  match read_char(ctx) {
    Some('+') | Some('-') => return ctx.lex_decimal_exponent_sign!(start~)
    Some(c) => {
      if c >= '0' && c <= '9' {
        return ctx.lex_decimal_exponent_integer!(start~)
      }
      ctx.offset -= 1
      invalid_char!(ctx)
    }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_exponent_sign(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  match read_char(ctx) {
    Some(c) => {
      if c >= '0' && c <= '9' {
        return ctx.lex_decimal_exponent_integer!(start~)
      }
      ctx.offset -= 1
      invalid_char!(ctx)
    }
    None => raise InvalidEof
  }
}

///|
fn ParseContext::lex_decimal_exponent_integer(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  for {
    match read_char(ctx) {
      Some(c) => {
        if ((c >= '0' && c <= '9') || c == '_') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end!(start, ctx.offset)
      }
      None => return ctx.lex_number_end!(start, ctx.offset)
    }
  }
}

/// 解析日期
fn ParseContext::lex_data(
  ctx : ParseContext,
  start~ : Int
) -> String!ParseError {
  let end = start + 10
  let data = ctx.input.substring(start~, end~)
  if (data.char_at(4) != '-' || data.char_at(7) != '-') {
    invalid_char!(ctx)
  }

  // 读取其中的月日
  let year_s = data.substring(start = 0, end = 4)
  let mut year = 0
  let month_s = data.substring(start = 5, end = 7)
  let mut month = 0
  let day_s = data.substring(start = 8)
  let mut day = 0
  try {
    year = @strconv.parse_int!(year_s)
    month = @strconv.parse_int!(month_s)
    day = @strconv.parse_int!(day_s)
  } catch {
    _ => raise InvalidNumber(ctx.line, ctx.column, month_s)
  }

  // 检查月日
  match(month){
    // 大月
    1 | 3 | 5 | 7 | 8 | 10 | 12 => {
      if (day >= 1 && day <= 31) {
        return data
      }else {
        raise InvalidNumber(ctx.line, ctx.column, day_s)
      }
    }

    // 小月
    4 | 6 | 9 | 11 => {
      if (day >= 1 && day <= 30) {
        return data
      }else {
        raise InvalidNumber(ctx.line, ctx.column, day_s)
      }
    }

    // 二月
    2 => {
      if ((is_leap_year(year) && day >= 1 && day <= 29) || (not(is_leap_year(year)) && day >= 1 && day <= 28)) {
        return data
      }else {
        raise InvalidNumber(ctx.line, ctx.column, day_s)
      }
    }

    _ => {
      raise InvalidNumber(ctx.line, ctx.column, month_s)
    }
  }
}

/// 检查是否闰年
fn is_leap_year(year : Int) -> Bool {
  if(year % 100 == 0){
    // 整百年，需要是 400 的倍数
    if(year % 400 == 0){
      return true
    }else{
      return false
    }
  }else{
    // 非整百年
    if(year % 4 == 0){
      return true
    }else{
      return false
    }
  }
}

///|
fn ParseContext::lex_zero(
  ctx : ParseContext,
  start~ : Int
) -> Double!ParseError {
  match read_char(ctx) {
    // 小数
    Some('.') => ctx.lex_decimal_point!(start~)

    //科学计数法
    Some('e' | 'E') => ctx.lex_decimal_exponent!(start~)

    // 二进制数
    Some('b' | 'B') => ctx.lex_binary!(start~)

    // 八进制数
    Some('o' | 'O') => ctx.lex_octal!(start~)

    // 十六进制数
    Some('x' | 'X') => ctx.lex_hexadecimal!(start~)

    // 其他情况，0后面不能跟其他数字，报错
    Some(c) => {
      if ((c >= '0' && c <= '9') || c == '_') {
        ctx.offset -= 1
        invalid_char!(ctx)
      }
      ctx.offset -= 1
      return ctx.lex_number_end!(start, ctx.offset)
    }
    None => return ctx.lex_number_end!(start, ctx.offset)
  }
}

/// 解析二进制数
/// 非十进制数需要先转为 Int 类型，才能转化为 Double 类型
fn ParseContext::lex_binary(ctx : ParseContext, start~ : Int) -> Double!ParseError{
  for {
    match read_char(ctx) {
      Some(c) => {
        if ((c >= '0' && c <= '1') || c == '_') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end_bases!(start, ctx.offset)
      }
      None => return ctx.lex_number_end_bases!(start, ctx.offset)
    }
  }
}

/// 解析八进制数
/// 非十进制数需要先转为 Int 类型，才能转化为 Double 类型
fn ParseContext::lex_octal(ctx : ParseContext, start~ : Int) -> Double!ParseError{
  for {
    match read_char(ctx) {
      Some(c) => {
        if ((c >= '0' && c <= '7') || c == '_') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end_bases!(start, ctx.offset)
      }
      None => return ctx.lex_number_end_bases!(start, ctx.offset)
    }
  }
}

/// 解析十六进制数
/// 非十进制数需要先转为 Int 类型，才能转化为 Double 类型
fn ParseContext::lex_hexadecimal(ctx : ParseContext, start~ : Int) -> Double!ParseError{
  for {
    match read_char(ctx) {
      Some(c) => {
        if ((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F') || c == '_') {
          continue
        }
        ctx.offset -= 1
        return ctx.lex_number_end_bases!(start, ctx.offset)
      }
      None => return ctx.lex_number_end_bases!(start, ctx.offset)
    }
  }
}

///|
fn ParseContext::lex_number_end(
  ctx : ParseContext,
  start : Int,
  end : Int
) -> Double!ParseError {
  let s = ctx.input.substring(start~, end~)
  try {
    @strconv.parse_double!(s)
  } catch {
    _ => raise InvalidNumber(ctx.line, ctx.column, s)
  }
}


/// 非十进制数时，解析数字
/// 非十进制数需要先转为 Int 类型，才能转化为 Double 类型
fn ParseContext::lex_number_end_bases(ctx : ParseContext,
  start : Int,
  end : Int
) -> Double!ParseError {
  let s = ctx.input.substring(start~, end~)
  let mut n: Int = 0
  try {
    n = @strconv.parse_int!(s)
    n.to_double()
  } catch {
    _ => raise InvalidNumber(ctx.line, ctx.column, s)
  }
}