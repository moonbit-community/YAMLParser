/// 解析错误处理：打印错误信息后终止程序
fn report_error(err : ParseError) -> Unit!ParseError {
  println(ParseError::to_string(err))
  raise err
}

/// 统计字符串前导空格数
fn count_leading_spaces(ctx: ParseContext) -> Int!ParseError {
  let mut count = 0
  while(ctx.offset < ctx.end_offset) {
    match read_char(ctx) {
      Some(' ') => {
        count = count + 1
      }
      Some('\n') => {
        count = 0
        continue
      }
      Some(_) => {
        back_offset(ctx, 1)
        break
      }

      _ => {
        raise InvalidEof
      }
    }
  }
  return count
}

/// 递归合并两个对象（用于继承）
/// 只能合并两个对象
fn deep_merge(target : YamlValue, source : YamlValue, ctx: ParseContext) -> YamlValue!ParseError {
  match (target, source) {
    (YamlValue :: Object(targetObj), Object(sourceObj)) => {
      for sourcePair in sourceObj {
          if(not(targetObj.contains(sourcePair.0))){
            // 不存在这个键，直接添加
            targetObj.set(sourcePair.0, sourcePair.1)
          }
      }
    }
    _ => {
      raise InvalidMerge(ctx.line, ctx.column, "Invalid merge' at line " + ctx.line.to_string() + ", column " + ctx.column.to_string())
    }
  }
  return target
}

/// 跳过空白或注释，一直跳到非空白或换行
fn skip_ws_and_comments_no_wrap(ctx: ParseContext) -> Unit!ParseError {
  while(ctx.offset < ctx.end_offset) {
    match peek_char(ctx) {
      Some(' ' | '\t' | '\r') => {
          let _ = read_char(ctx)
      }

      // 读到换行就结束
      Some('\n') => {
        let _ = read_char(ctx)
        break
      }

      // 处理注释
      Some('#') => {
        let _ = read_char(ctx);
        let mut c = read_char(ctx)
        while (c.unwrap() != '\n') {
          c = read_char(ctx)
        }
        let _ = read_char(ctx)
        continue
      }

      Some(_) => break

      None => raise InvalidEof
    }
  }
}

/// 跳过空白或注释，一直跳到非空白或换行
/// 换行后接着跳，直到非空白
fn skip_ws_and_comments(ctx: ParseContext) -> Unit raise ParseError {
  while(true) {
    match peek_char(ctx) {
      
      Some(' ' | '\t' | '\r' | '\n') => {
          let _ = read_char(ctx)
      }

      // 处理注释
      Some('#') => {
        let _ = read_char(ctx)
        let mut c = read_char(ctx)
        while (c.unwrap() != '\n') {
          c = read_char(ctx)
        }
        let _ = read_char(ctx)
        continue
      }

      Some(_) => break

      None => raise InvalidEof
    }
  }
}

/// 主解析器：直接解析 YAML 文本，不分离词法和语法
pub fn parse_yaml(input : String) -> YamlValue raise ParseError {
  let ctx = ParseContext::make(input)  // 解析文本
  
  let anchors: Map[String, YamlValue] = {}       // 锚点存储表
  let container_stack : @deque.T[YamlValue] = @deque.new()  // 容器栈，存储容器，第一个值为锚点名称，
                                                                       // 若有锚点，则是锚点名称，若无则是 None。第二个值为容器

  let root_container = YamlValue::Object({})  // 根对象，也是根容器
  container_stack.push_front(root_container)

  let intent_stack : @deque.T[Int] = @deque.new()  // 前导空格数量栈
  intent_stack.push_front(0)

  let result = parse_mapping(ctx, container_stack, intent_stack, anchors)
  return result
}

fn parse_mapping(ctx: ParseContext, container_stack: @deque.T[YamlValue], intent_stack: @deque.T[Int], anchors: Map[String, YamlValue]) -> YamlValue!ParseError {
  println("parse_mapping")
  let mut current_container = YamlValue::Object({})  // 当前的容器
  let mut current_intend = 0
  // 获取当前容器
  match (container_stack.front(), intent_stack.front()) {
    (Some(front_container), Some(front_indent)) => {
      current_container = front_container
      current_intend = front_indent
    }
    _ => {
      raise InvalidIndentation(ctx.line, ctx.column)
    }
  }

  let mut count_leading_spaces_this = count_leading_spaces(ctx)
  if(count_leading_spaces_this > current_intend){
    // 当前缩进过多，报错
    raise InvalidIndentation(ctx.line, ctx.column)
  }

  // 开始解析映射，需要解析到缩进小于当前 map 的地方
  // 缩进刚好为栈顶缩进，使用
  while(count_leading_spaces_this == current_intend && ctx.offset < ctx.end_offset){
    println(count_leading_spaces_this)
    let key = parse_key(ctx)
    skip_ws_and_comments_no_wrap(ctx)
    let colon = read_char(ctx).unwrap()  // 读取冒号
    // key后面不跟冒号，报错
    if(colon != ':'){
      report_error(InvalidChar(ctx.line, ctx.column, colon))
    }

    skip_ws_and_comments_no_wrap(ctx)
    let value = parse_value(ctx, container_stack, intent_stack, anchors)
    println("parse value finished")
    // 将当前解析的值加入到映射中
    match(current_container) {
      Object(obj) => {
        obj.set(key, value)
      }
      _ => {
        
        raise InvalidIndentation(ctx.line, ctx.column)  // 报错需要斟酌
      }
    }
    count_leading_spaces_this = count_leading_spaces(ctx)
  }
  
  // 当前映射解析完毕，弹栈
  if(count_leading_spaces_this < current_intend) {
    match (container_stack.pop_front(), intent_stack.pop_front()) {
      (Some(_), Some(_)) => {
        back_offset(ctx, count_leading_spaces_this)  // 将跳过的空格回退，确保后续可以正常计算缩进
      }
      _ => {
        raise InvalidIndentation(ctx.line, ctx.column)
      }
    }
  }

  return current_container
}

/// 解析键
fn parse_key(ctx: ParseContext) -> String {
  let buf = StringBuilder::new()  // 存储键
  let mut ch_opt = read_char(ctx)
  while(not(ch_opt.is_empty())) {
    let ch = ch_opt.unwrap()
    if(is_latter_number(ch)) {
      buf.write_char(ch)
      ch_opt = read_char(ctx)

    }else{
      back_offset(ctx, 1)
      break
    }
  }
  buf.to_string()
}

/// 判断字符是否为字母或数字或下划线
fn is_latter_number(ch: Char) -> Bool {
  if((ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'){
    true
  }else {
    false
  }
}

/// 解析值
fn parse_value(ctx: ParseContext, container_stack: @deque.T[YamlValue], intent_stack: @deque.T[Int], anchors: Map[String, YamlValue]) -> YamlValue!ParseError {
  println("parse_value")
  //skip_ws_and_comments_no_wrap!(ctx)
  match(peek_char(ctx)) {
    Some(' ') => {
      // 换行后开头是空格，表示要进入新的容器
      let intent = count_leading_spaces!(ctx)  
      
      println(intent)

      match(intent_stack.front()) {
        Some(front_indent) => {
          if(intent <= front_indent) {
          // 当前缩进较小，报错
            raise InvalidIndentation(ctx.line, ctx.column)

          } else{
            // 当前缩进更多，需要进入新容器
            match(peek_char(ctx)){
              Some('-') => {
                // 需要解析数组
                let _ = read_char(ctx)
                let new_container: YamlValue = YamlValue::Array([])
                container_stack.push_front(new_container)
                intent_stack.push_front(intent)
                return parse_array!(ctx, container_stack, intent_stack, anchors)
              }

              Some('<') => {
                // 解析引用，需要深度合并
                let _ = read_char(ctx)  // 消耗掉第一个 '<'
                let mut ch = read_char(ctx).unwrap()
                if(ch != '<'){
                  // 第二个字符不是'<'，报错
                  raise InvalidMerge(ctx.line, ctx.column, ch.to_string())
                }

                skip_ws_and_comments!(ctx)  // 读掉其中的空白
                ch = read_char(ctx).unwrap()  // 读取冒号
                if(ch != ':') {
                  // 不是':'，报错
                  raise InvalidMerge(ctx.line, ctx.column, ch.to_string())
                }

                skip_ws_and_comments!(ctx)  // 读掉其中的空白
                ch = read_char(ctx).unwrap()  // 读取 '*'
                if(ch != '*') {
                  raise InvalidMerge(ctx.line, ctx.column, ch.to_string())
                }
                
                // 解析引用
                let new_container: YamlValue = YamlValue::Object({})
                container_stack.push_front(new_container)
                intent_stack.push_front(intent)
                let _ = parse_quote(anchors, new_container, ctx)
                return parse_mapping!(ctx, container_stack, intent_stack, anchors)
              }

              Some(_) => {
                // 其他情况，解析下级映射
                println(11111)
                println(container_stack.front())
                let new_container: YamlValue = YamlValue::Object({})
                container_stack.push_front(new_container)
                intent_stack.push_front(intent)
                let this_key = parse_key(ctx)
                skip_ws_and_comments_no_wrap(ctx)
                let colon = read_char(ctx).unwrap()  // 读取冒号
                // key后面不跟冒号，报错
                if(colon != ':'){
                  report_error(InvalidChar(ctx.line, ctx.column, colon))
                }
                skip_ws_and_comments_no_wrap(ctx)
                let value = parse_value(ctx, container_stack, intent_stack, anchors)
                match(container_stack.front()){
                  Some(YamlValue :: Object(obj)) => {
                    // 当前栈顶容器为对象，继续解析
                    obj.set(this_key, value)
                  }
                  _ => {
                    raise InvalidContainer(ctx.line, ctx.column)
                  }
                }
                
                return parse_mapping!(ctx, container_stack, intent_stack, anchors)
              }

              None => {
                raise InvalidEof
              }
            }
          }
        }

        None => {
          raise InvalidIndentation(ctx.line, ctx.column)
        }
      }
      
    }

    Some('&') => {
      // 解析锚点
      let _ = read_char(ctx)
      skip_ws_and_comments_no_wrap!(ctx)  // 跳过空格
      let anchor = parse_key(ctx)  // 获取锚点名称
      println("锚点名称：" + anchor)

      match(container_stack.front()) {
          Some(front_container) => {
            anchors.set(anchor, front_container)
            println("当前锚点属性为：" + front_container.to_string())
          }
          _ => {
            raise InvalidIndentation(ctx.line, ctx.column)
          }
      }

      // 继续向后解析
      skip_ws_and_comments_no_wrap!(ctx)
      parse_value!(ctx, container_stack, intent_stack, anchors)
    }

    // 解析数组的引用
    Some('*') => {
      match(container_stack.front()) {
          Some(front_container) => {
            parse_quote!(anchors, front_container, ctx)
            //parse_mapping!(ctx, container_stack, intent_stack, anchors)
          }
          _ => {
            raise InvalidIndentation(ctx.line, ctx.column)
          }
      }
    }

    // 其他情况，解析为标量
    Some(_) => {
      println("lex_value")
      lex_value!(ctx)
    }

    None => {
      raise InvalidEof
    }
  }
}


/// 解析数组
fn parse_array(ctx: ParseContext, container_stack: @deque.T[YamlValue], intent_stack: @deque.T[Int], anchors: Map[String, YamlValue]) -> YamlValue!ParseError {

  let mut current_container = YamlValue::Array([])  // 当前的容器
  let mut current_intend = 0
  // 获取当前容器
  match (container_stack.front(), intent_stack.front()) {
    (Some(front_container), Some(front_indent)) => {
      current_container = front_container
      current_intend = front_indent
    }
    _ => {
      raise InvalidIndentation(ctx.line, ctx.column)
    }
  }

  let mut count_leading_spaces_this = count_leading_spaces!(ctx)
  if(count_leading_spaces_this > current_intend){
    // 当前缩进过多，报错
    raise InvalidIndentation(ctx.line, ctx.column)
  }

  // 开始解析映射，需要解析到缩进小于当前 array 的地方
  skip_ws_and_comments_no_wrap!(ctx)
  let value = parse_value!(ctx, container_stack, intent_stack, anchors)
  println(value)

  // 将当前解析的值加入到数组中
  match(current_container) {
    Array(arr) => {
      arr.push(value)
      println(arr)
    }
    _ => {
      raise InvalidIndentation(ctx.line, ctx.column)  // 报错需要斟酌
    }
  }
  
  count_leading_spaces_this = count_leading_spaces!(ctx)

  while(count_leading_spaces_this == current_intend && ctx.offset < ctx.end_offset){
    println("parse array")
    skip_ws_and_comments_no_wrap!(ctx)
      println(peek_char(ctx).unwrap())
    if(peek_char(ctx).unwrap() == '-'){
      println(peek_char(ctx).unwrap())
      let _ = read_char(ctx)
    }
    
    skip_ws_and_comments_no_wrap!(ctx)
    let value = parse_value!(ctx, container_stack, intent_stack, anchors)
    println(value)

    // 将当前解析的值加入到数组中
    match(current_container) {
      Array(arr) => {
        arr.push(value)
      }
      _ => {
        raise InvalidIndentation(ctx.line, ctx.column)  // 报错需要斟酌
      }
    }

    count_leading_spaces_this = count_leading_spaces!(ctx)
  }

  // 当前数组解析完毕，弹栈
  if(count_leading_spaces_this < current_intend) {
    match (container_stack.pop_front(), intent_stack.pop_front()) {
      (Some(_), Some(_)) => {
        back_offset(ctx, count_leading_spaces_this)  // 将跳过的空格回退，确保后续可以正常计算缩进
      }
      _ => {
        raise InvalidIndentation(ctx.line, ctx.column)
      }
    }
  }else {
    raise InvalidIndentation(ctx.line, ctx.column)
  }

  return current_container
}

/// 解析引用
fn parse_quote(anchors: Map[String, YamlValue], target: YamlValue, ctx: ParseContext) -> YamlValue!ParseError{
  skip_ws_and_comments!(ctx)  // 读掉其中的空白
  // 获取源锚点
  let anchor = parse_key(ctx)  // 读取锚点
  if(anchors.contains(anchor)){
    return deep_merge!(target, anchors.get(anchor).unwrap(), ctx)
  }else {
    raise UndefinedAnchor(ctx.line, ctx.column, anchor)
  }
}