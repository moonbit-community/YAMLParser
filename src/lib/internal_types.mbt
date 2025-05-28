/// 解析的文本
priv struct ParseContext {
  mut offset : Int
  input : String
  end_offset : Int
  mut line : Int
  mut column : Int
}

fn ParseContext::make(input : String) -> ParseContext {
  { offset: 0, input, end_offset: input.length(), line: 1, column: 0}
}


///|
// YAML 字符类别
priv type YAMLCharClass Array[(Char, Char)]

///|
// 创建 YAML 字符类别
fn YAMLCharClass::of(array : Array[(Char, Char)]) -> YAMLCharClass {
  YAMLCharClass(array)
}

///|
// 从数组创建 YAML 字符类别
fn YAMLCharClass::from_array(array : Array[(Char, Char)]) -> YAMLCharClass {
  YAMLCharClass(array)
}

///|
// 判断字符是否在字符类别内
fn YAMLCharClass::contains(self : YAMLCharClass, c : Char) -> Bool {
  for left = 0, right = self._.length(); left < right; {
    let middle = (left + right) / 2
    let (min, max) = self._[middle]
    if c < min {
      continue left, middle
    } else if c > max {
      continue middle + 1, right
    } else {
      break true
    }
  } else {
    false
  }
}