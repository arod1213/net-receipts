import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/string

pub fn hash_csv(csv: dict.Dict(String, String)) {
  let bits =
    csv
    |> dict.fold("", fn(acc, k, v) { acc <> string.join([k, v], ":") })
    |> bit_array.from_string

  crypto.hash(crypto.Sha224, bits)
}
