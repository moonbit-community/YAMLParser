/// 可从 YAML 转换的类型
pub(open) trait FromYaml {
  from_yaml(YamlValue) -> Self!ParseError
}

/// 从 YAML 解析值
pub fn from_yaml[T : FromYaml](
  yaml : YamlValue,
) -> T!ParseError {
  FromYaml::from_yaml!(yaml)
}

/// 解析错误
fn decode_error[T](msg : String) -> T!ParseError {
  raise YamlDecodeError((msg))
}

/// 解析布尔值
pub impl FromYaml for Bool with from_yaml(yaml) {
  match yaml {
    True => true
    False => false
    _ => decode_error!("Bool::from_yaml: expected boolean")
  }
}

/// 解析整数
pub impl FromYaml for Int with from_yaml(yaml) {
  match yaml {
    Number(n) => n.to_int()
    _ => decode_error!("Int::from_yaml: expected number")
  }
}

/// 解析 64 位整数
pub impl FromYaml for Int64 with from_yaml(yaml) {
  match yaml {
    String(str) =>
      try {
        @strconv.parse_int64!(str)
      } catch {
        error =>
          decode_error!("Int64::from_yaml: parsing failure \{error}")
      }
    _ =>
      decode_error!(
        "Int64::from_yaml: expected number in string representation",
      )
  }
}

/// 解析无符号整数
pub impl FromYaml for UInt with from_yaml(yaml) {
  match yaml {
    Number(n) => n.to_uint()
    _ => decode_error!("UInt::from_yaml: expected number")
  }
}

/// 解析 64 位无符号整数
pub impl FromYaml for UInt64 with from_yaml(yaml) {
  match yaml {
    String(str) =>
      try {
        @strconv.parse_uint64!(str)
      } catch {
        error =>
          decode_error!("UInt64::from_yaml: parsing failure \{error}")
      }
    _ =>
      decode_error!(
        "UInt64::from_yaml: expected number in string representation",
      )
  }
}


/// 解析浮点数
pub impl FromYaml for Double with from_yaml(yaml) {
  match yaml {
    Number(n) => n
    _ => decode_error!("Double::from_yaml: expected number")
  }
}

/// 解析字符串
pub impl FromYaml for String with from_yaml(yaml) {
  match yaml {
    String(a) => a
    _ => decode_error!("String::from_yaml: expected string")
  }
}

/// 解析字符
pub impl FromYaml for Char with from_yaml(yaml) {
  match yaml {
    String(a) =>
      if a.length() != 1 {
        decode_error!("Char::from_yaml: expected single character")
      } else {
        a[0].to_char().unwrap()
      }
    _ => decode_error!("Char::from_yaml: expected string")
  }
}

/// 解析 YAML 数组
pub impl[X : FromYaml] FromYaml for Array[X] with from_yaml(yaml) {
  match yaml {
    Array(a) => {
      let res : Array[X] = Array::new(capacity=a.length())
      for i = 0; i < a.length(); i = i + 1 {
        res.push(FromYaml::from_yaml!(a[i]))
      }
      res
    }
    _ => decode_error!("Array::from_yaml: expected array")
  }
}

/// 解析固定大小的 YAML 数组
pub impl[X : FromYaml] FromYaml for FixedArray[X] with from_yaml(yaml) {
  match yaml {
    Array(a) => {
      let len = a.length()
      if len == 0 {
        return []
      }
      let res : FixedArray[X] = FixedArray::make(
        len,
        FromYaml::from_yaml!(a[0]),
      )
      for i in 1..<len {
        res[i] = FromYaml::from_yaml!(a[i])
      }
      res
    }
    _ => decode_error!("FixedArray::from_yaml: expected array")
  }
}

///|
/// 解析 YAML 映射（键值对）
pub impl[V : FromYaml] FromYaml for Map[String, V] with from_yaml(yaml) {
  match yaml {
    Object(obj) => {
      let res: Map[String, V] = Map::new()
      for k, v in obj {
        res[k] = FromYaml::from_yaml!(v)
      }
      res
    }
    _ => decode_error!("Map::from_yaml: expected object")
  }
}

/// 解析可选值（YAML `null`）
pub impl[T : FromYaml] FromYaml for T? with from_yaml(yaml) {
  match yaml {
    Null => None
    Array([value]) => Some(FromYaml::from_yaml!(value))
    _ => decode_error!("Option::from_yaml: expected array or null")
  }
}

/// 解析 `Result` 类型
pub impl[Ok : FromYaml, Err : FromYaml] FromYaml for Result[Ok, Err] with from_yaml(
  yaml
) {
  match yaml {
    Object(obj) => {
      if obj.size() != 1 {
        decode_error!("Result::from_yaml: expected object with one field")
      }
      match obj {
        { "Ok": ok, .. } => Ok(FromYaml::from_yaml!(ok))
        { "Err": err, .. } => Err(FromYaml::from_yaml!(err))
        _ =>
          decode_error!(
            "Result::from_yaml: expected object with Ok or Err field",
          )
      }
    }
    _ => decode_error!("Result::from_yaml: expected object")
  }
}

/// 解析 `Unit` 类型
pub impl FromYaml for Unit with from_yaml(yaml) {
  match yaml {
    Null => ()
    _ => decode_error!("Unit::from_yaml: expected null")
  }
}

/// 解析 `YamlValue` 本身
pub impl FromYaml for YamlValue with from_yaml(yaml) {
  guard true else { decode_error!("Unreachable") }
  yaml
}