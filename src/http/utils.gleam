import gleam/dict
import gleam/list
import gleam/string

pub fn query_to_dict(query: String) -> dict.Dict(String, String) {
  query
  |> string.split("&")
  |> list.fold(dict.new(), fn(d, param) { string_to_dict(d, param, "=") })
}

fn string_to_dict(d, s, sep) {
  case string.split_once(s, sep) {
    Ok(#(k, v)) -> dict.insert(d, k, v)
    Error(_) -> d
  }
}
