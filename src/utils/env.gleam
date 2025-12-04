import envoy
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn load_dotenv() {
  let assert Ok(lines) =
    simplifile.read(".env") |> result.map(fn(x) { x |> string.split("\n") })

  lines
  |> list.each(fn(x) {
    case x |> string.split_once("=") {
      Ok(val) -> {
        let #(k, v) = val
        envoy.set(k, v)
      }
      Error(_) -> Nil
    }
    x
  })
}
