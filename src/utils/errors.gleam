import gleam/option.{type Option, None, Some}

pub fn result_as_option(res: Result(a, b)) -> Option(a) {
  case res {
    Ok(s) -> Some(s)
    Error(_) -> None
  }
}

pub fn result_to_nil(res: Result(a, b)) -> Result(a, Nil) {
  case res {
    Ok(s) -> Ok(s)
    Error(_) -> Error(Nil)
  }
}
