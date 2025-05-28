/// YAML 数据类型
pub(all) enum YamlValue {
  Null
  True
  False
  Number(Double)
  String(String)
  Array(Array[YamlValue])
  Object(Map[String, YamlValue])
} derive(Eq)

/// 位置
pub(all) struct Position {
  line : Int    // 1-based
  column : Int  // 0-based
} derive(Eq)



/// 解析错误类型
pub(all) type! ParseError {
  InvalidChar(Int, Int, Char)         // 错误字符
  InvalidEof                          // 意外文件结束
  InvalidNumber(Int, Int, String)     // 错误数字
  InvalidIdentEscape(Int, Int)        // 错误转义字符
  InvalidIndentation(Int, Int)        // 缩进错误
  UndefinedAnchor(Int, Int, String)   // 未定义锚点
  CircularReference(Int, Int, String) // 循环引用
  InvalidMerge(Int, Int, String)      // 继承合并时类型错误
  InvalidComplexKey(Int, Int)         // 复杂键语法错误
  YamlDecodeError(String)
} derive(Eq, Show)


/// 将 ParseError 转换为字符串
pub fn to_string(self : ParseError) -> String {
  match self {
    InvalidChar(line, column, c) =>
      "Invalid character '" + c.to_string() + "' at line " + line.to_string() + ", column " + column.to_string()
    InvalidEof => "Unexpected end of file"
    InvalidNumber(line, column, s) =>
      "Invalid number " + s + " at line " + line.to_string() + ", column " + column.to_string()
    InvalidIdentEscape(line, column) =>
      "Invalid escape sequence in identifier at line " + line.to_string() + ", column " + column.to_string()
    InvalidIndentation(line, column) =>
      "Invalid indentation at line " + line.to_string() + ", column " + column.to_string()
    UndefinedAnchor(line, column, anchor) =>
      "Undefined anchor '" + anchor + "' at line " + line.to_string() + ", column " + column.to_string()
    CircularReference(line, column, anchor) =>
      "Circular reference detected for anchor '" + anchor + "' at line " + line.to_string() + ", column " + column.to_string()
    InvalidMerge(line, column, anchor) =>
      "Invalid merge for anchor '" + anchor + "' at line " + line.to_string() + ", column " + column.to_string()
    InvalidComplexKey(line, column) =>
      "Invalid complex key syntax at line " + line.to_string() + ", column " + column.to_string()
    YamlDecodeError(str) => 
      str
  }
}

// pub impl Show for ParseError with output(self, logger) {
//   logger.write_string(self.to_string())
// }

pub impl Show for YamlValue with output(self, logger) {
  match self {
    Null => logger.write_string("Null")
    True => logger.write_string("True")
    False => logger.write_string("False")
    Number(n) => {
      logger.write_string("Number(")
      Show::output(n, logger)
      logger.write_string(")")
    }
    String(s) => {
      logger.write_string("String(")
      Show::output(s, logger)
      logger.write_string(")")
    }
    Array(a) => {
      logger.write_string("Array(")
      Show::output(a, logger)
      logger.write_string(")")
    }
    
    Object(o) => {
      logger.write_string("Object(")
      Show::output(o, logger)
      logger.write_string(")")
    }
  }
}