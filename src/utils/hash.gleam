import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/list
import gleam/string

pub fn hash_csv(csv: dict.Dict(String, String)) {
  let joined =
    csv
    |> dict.to_list
    |> list.map(fn(x) {
      let #(a, b) = x
      string.join([a, b], ":")
    })
    |> string.join("|")

  let bits = joined |> bit_array.from_string
  echo bit_array.is_utf8(bits) as "UTF8 VALID"

  crypto.hash(crypto.Sha256, bits)
  |> bit_array.base64_encode(False)
}
