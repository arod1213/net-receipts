import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import utils/cmp

pub fn most_common_entry(vals: List(a)) {
  vals
  |> list.fold(dict.new(), fn(acc, x) {
    let count = case dict.get(acc, x) {
      Ok(c) -> c + 1
      Error(_) -> 1
    }
    dict.insert(acc, x, count)
  })
  |> dict.to_list
  |> list.max(fn(a, b) {
    let #(_, a_count) = a
    let #(_, b_count) = b
    case a_count > b_count {
      True -> order.Gt
      False ->
        case a_count == b_count {
          True -> order.Eq
          False -> order.Lt
        }
    }
  })
  |> result.map(fn(x) {
    let #(val, _) = x
    val
  })
}

pub fn strings_are_equivalent(a, b) {
  let a_clean = a |> clean_str
  let b_clean = b |> clean_str

  let min = int.min(string.length(a_clean), string.length(b_clean))
  use <- bool.guard(min < 2, False)

  contain_either(a_clean, b_clean)
  // TODO: add misspelling tolerance here
}

fn contain_either(a, b) {
  a |> string.contains(b) || b |> string.contains(a)
}

fn clean_str(s: String) -> String {
  s
  |> string.lowercase
  |> string.replace(" ", "")
  |> string.replace("'", "")
  |> string.replace("(", "")
  |> string.replace(")", "")
  |> string.replace("{", "")
  |> string.replace("}", "")
  |> string.replace("[", "")
  |> string.replace("]", "")
}

pub fn char_difference(s1, s2) -> Int {
  loop(s1, s2, 0, 0)
}

// do not expose this func
fn loop(s1, s2, idx, acc) -> Int {
  let max = int.max(string.length(s1), string.length(s2))
  case idx >= max {
    True -> acc
    False -> {
      let a = s1 |> string.slice(idx, 1)
      let b = s2 |> string.slice(idx, 1)
      case a != b {
        True -> loop(s1, s2, idx + 1, acc + 1)
        False -> loop(s1, s2, idx + 1, acc)
      }
    }
  }
}

pub fn fuzzy_percent(s1, s2) -> Float {
  let max_val = cmp.max(string.length(s1), string.length(s2)) |> int.to_float
  let distance = levenshtein(s1, s2) |> int.to_float
  distance /. max_val
}

fn levenshtein(s1: String, s2: String) -> Int {
  let l1 = string.length(s1)
  let l2 = string.length(s2)
  levenshtein_matrix(s1, s2, 0, 0, l1, l2)
}

fn levenshtein_matrix(
  s1: String,
  s2: String,
  i: Int,
  j: Int,
  l1: Int,
  l2: Int,
) -> Int {
  case i == l1, j == l2 {
    True, True -> 0
    True, False -> l2 - j
    False, True -> l1 - i
    False, False -> {
      let c1 = string.slice(s1, i, i + 1)
      let c2 = string.slice(s2, j, j + 1)
      let cost = case c1 == c2 {
        True -> 0
        False -> 1
      }

      // Recursive calls
      let delete = 1 + levenshtein_matrix(s1, s2, i + 1, j, l1, l2)
      let insert = 1 + levenshtein_matrix(s1, s2, i, j + 1, l1, l2)
      let substitute = cost + levenshtein_matrix(s1, s2, i + 1, j + 1, l1, l2)

      cmp.min(delete, cmp.min(insert, substitute))
    }
  }
}
