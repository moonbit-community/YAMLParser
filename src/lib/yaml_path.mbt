/// YAML 解析路径
pub enum YamlPath {
  //Root
  Key(YamlPath, mut key~ : String)
  Index(YamlPath, mut index~ : Int)
} derive(Eq)

///|
/// 添加索引（用于数组）
pub fn add_index(self : YamlPath, index : Int) -> YamlPath {
  Index(self, index~)
}

///|
/// 添加键（用于对象）
pub fn add_key(self : YamlPath, key : String) -> YamlPath {
  Key(self, key~)
}

///|
/// 输出 YAML 路径到日志
// pub fn output(self : YamlPath, logger : &Logger) -> Unit {
//   match self {
//     Root => logger.write_string("$")
//     Key(p, key~) => logger..write_object(p)..write_string(".").write_string(key)
//     Index(p, index~) =>
//       logger
//       ..write_object(p)
//       ..write_string("[")
//       ..write_object(index)
//       .write_string("]")
//   }
// }

///|
/// 更新 Key（可变操作）
fn update_key_inplace(self : YamlPath, key : String) -> Unit {
  match self {
    Key(_) as k => k.key = key
    _ => abort("the variant is not Key")
  }
}

///|
/// 更新 Index（可变操作）
fn update_index_inplace(self : YamlPath, index : Int) -> Unit {
  match self {
    Index(_) as i => i.index = index
    _ => abort("the variant is not Index")
  }
}