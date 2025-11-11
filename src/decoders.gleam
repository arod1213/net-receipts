import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import tempo
import tempo/date

pub fn date_decoder() {
  decode.map(decode.string, fn(str) {
    let #(date, _, _) = tempo.parse_any(str)
    date
  })
}

pub fn date_to_string(x) {
  x |> date.format(tempo.ISO8601Date)
}

pub fn date_to_json(x) {
  x |> date_to_string |> json.string
}

pub fn parse_clean_float(s: String) -> Result(Float, Nil) {
  let str =
    s
    |> string.trim
  case string.starts_with(str, ".") {
    True -> "0" <> str
    False -> str
  }
  |> float.parse
}

pub fn float_decoder() {
  decode.one_of(decode.float, or: [
    decode.map(decode.int, fn(x) { x |> int.to_float }),
  ])
}

pub type CSVError(a) {
  NotFound
  DecodeError(a)
}

pub fn decode_one_field(
  dict: dict.Dict(String, String),
  fields: List(String),
  decoder: fn(String) -> Result(a, b),
) {
  case fields {
    [] -> Error(NotFound)
    [first, ..rest] -> {
      case dict |> dict.get(first) {
        Ok(s) -> decoder(s) |> result.map_error(fn(e) { e |> DecodeError })
        Error(_) -> decode_one_field(dict, rest, decoder)
      }
    }
  }
}

pub fn field_any(
  names,
  decoder: decode.Decoder(a),
  make: fn(a) -> decode.Decoder(b),
) {
  let decoders =
    names
    |> list.map(fn(name) { decode.field(name, decoder, make) })
  case decoders {
    [] -> panic as "no names provided"
    [first, ..rest] -> decode.one_of(first, or: rest)
  }
}

pub fn no_whitespace(str) -> Option(String) {
  case str |> string.trim {
    "" -> None
    s -> Some(s)
  }
}
