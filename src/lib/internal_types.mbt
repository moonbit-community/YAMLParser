///|
// YAML 解析上下文
priv struct YAMLContext {
  mut offset : Int       // 当前解析位置
  input : String         // 输入字符串
  end_offset : Int       // 输入字符串的总长度
}

///|
// 创建新的 YAML 解析上下文
fn YAMLContext::make(input : String) -> YAMLContext {
  { offset: 0, input, end_offset: input.length() }
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