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