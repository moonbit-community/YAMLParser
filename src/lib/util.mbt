///|读取下一个字符，会移动偏移量
fn read_char(ctx : ParseContext) -> Char? {
  if ctx.offset < ctx.end_offset {
    let c = ctx.input[ctx.offset]
    ctx.offset += 1
    let c1 = c.to_int()
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if ctx.offset < ctx.end_offset {
        let c2 = ctx.input[ctx.offset].to_int()
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          ctx.offset += 1
          let c3 = (c1 << 10) + c2 - 0x35fdc00
          return Some(Char::from_int(c3))
        }
      }
    }
    Some(c)
  } else {
    None
  }
}

/// 仅查看下一个字符，而不移动 offset
fn peek_char(ctx : ParseContext) -> Char? {
  if ctx.offset < ctx.end_offset {
    let c = ctx.input[ctx.offset]
    let c1 = c.to_int()
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if ctx.offset + 1 < ctx.end_offset {
        let c2 = ctx.input[ctx.offset + 1].to_int()
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          let c3 = (c1 << 10) + c2 - 0x35fdc00
          return Some(Char::from_int(c3))
        }
      }
    }
    Some(c)
  } else {
    None
  }
}

/// 读取指定位置的字符
fn peek_designated_char(ctx : ParseContext, position : Int) ->Char? {
  if position < ctx.end_offset {
    let c = ctx.input[position]
    let c1 = c.to_int()
    if c1 >= 0xD800 && c1 <= 0xDBFF {
      if position + 1 < ctx.end_offset {
        let c2 = ctx.input[position + 1].to_int()
        if c2 >= 0xDC00 && c2 <= 0xDFFF {
          let c3 = (c1 << 10) + c2 - 0x35fdc00
          return Some(Char::from_int(c3))
        }
      }
    }
    Some(c)
  } else {
    None
  }
}

/// 将 offset 移动指定位数
fn advance_offset(ctx : ParseContext, count: Int) -> Unit {
  let mut moved = 0
  while moved < count && ctx.offset < ctx.end_offset {
    let c1 = ctx.input[ctx.offset].to_int()
    ctx.offset += 1
    moved += 1
    // 如果当前是高代理项，并且下一个字符仍在范围内，确保一起跳过
    if c1 >= 0xD800 && c1 <= 0xDBFF && ctx.offset < ctx.end_offset {
      let c2 = ctx.input[ctx.offset].to_int()
      if c2 >= 0xDC00 && c2 <= 0xDFFF {
        ctx.offset += 1
      }
    }
  }
}

/// 将 offset 后移指定位数
fn back_offset(ctx : ParseContext, count: Int) -> Unit {
  let mut moved = 0
  while moved < count && ctx.offset < ctx.end_offset {
    let c1 = ctx.input[ctx.offset].to_int()
    ctx.offset -= 1
    moved += 1
    // 如果当前是高代理项，并且下一个字符仍在范围内，确保一起跳过
    if c1 >= 0xD800 && c1 <= 0xDBFF && ctx.offset < ctx.end_offset {
      let c2 = ctx.input[ctx.offset].to_int()
      if c2 >= 0xDC00 && c2 <= 0xDFFF {
        ctx.offset -= 1
      }
    }
  }
}

/// 检查字符是否为指定字符，且不考虑大小写
fn assert_char_escape(ctx : ParseContext, c : Char) -> Unit!ParseError {
  match read_char(ctx) {
    Some(c2) => if c == c2 || c.to_int() == c2.to_int() + 32 { () } else { back_offset(ctx, 1) }
    None => raise InvalidEof
  }
}

/// 检查字符是否为指定字符
fn assert_char(ctx : ParseContext, c : Char) -> Unit!ParseError {
  match read_char(ctx) {
    Some(c2) => if c == c2 { () } else { back_offset(ctx, 1) }
    None => raise InvalidEof
  }
}

/// 移动字符
fn invalid_char[T](ctx : ParseContext, shift~ : Int = 0) -> T!ParseError {
  let offset = ctx.offset + shift
  raise InvalidChar(offset_to_position(ctx.input, offset), ctx.input[offset])
}

/// 移动 offset
fn offset_to_position(input : String, offset : Int) -> Position {
  let mut line = 1
  let mut column = 0
  for i = 0; i < offset; i = i + 1 {
    let c = input[i]
    if c == '\n' {
      line += 1
      column = 0
    } else {
      column += 1
    }
  }
  return Position::{ line, column }
}
