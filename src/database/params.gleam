import gleam/int
import gleam/list
import gleam/string

pub fn row_placeholder(params params) {
  let vals =
    list.range(1, params)
    |> list.map(fn(i) { "$" <> i |> int.to_string })
    |> string.join(",")
  "(" <> vals <> ")"
}

fn placeholder(start, len) {
  let vals =
    list.range(start, start + len - 1)
    |> list.map(fn(i) { "$" <> i |> int.to_string })
    |> string.join(",")
  "(" <> vals <> ")"
}

pub fn query_placeholder(rows rows, params params) {
  list.range(0, rows - 1)
  |> list.map(fn(i) {
    let start = params * i + 1
    placeholder(start, params)
  })
  |> string.join(",")
}
