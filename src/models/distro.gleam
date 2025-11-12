import gleam/dict
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gsv
import providers/ascap
import providers/distrokid
import providers/globals
import providers/mlc
import providers/songtrust
import providers/soundexchange
import providers/vydia

pub type Distributor {
  Vydia
  Ascap
  BMI
  Songtrust
  Distrokid
  SoundExchange
  MLC
  Unknown
}

pub fn decoder() {
  decode.then(decode.string, fn(a) {
    case a {
      "Vydia" -> decode.success(Vydia)
      "Distrokid" -> decode.success(Distrokid)
      "BMI" -> decode.success(BMI)
      "Songtrust" -> decode.success(Songtrust)
      "ASCAP" -> decode.success(Ascap)
      "SoundExchange" -> decode.success(SoundExchange)
      "MLC" -> decode.success(MLC)
      "Unknown" -> decode.success(Unknown)
      _ -> decode.failure(Unknown, "Invalid field")
    }
  })
}

pub fn to_string(d: Distributor) -> String {
  case d {
    Distrokid -> "Distrokid"
    Ascap -> "ASCAP"
    Vydia -> "Vydia"
    Songtrust -> "Songtrust"
    SoundExchange -> "SoundExchange"
    MLC -> "MLC"
    BMI -> "BMI"
    Unknown -> "Unknown"
  }
}

pub fn encoder(d: Distributor) -> Json {
  d |> to_string |> json.string
}

pub fn distro_from_data(data: String, sep: String) -> option.Option(Distributor) {
  let dicts = data |> gsv.to_dicts(sep) |> result.unwrap([])
  let head = dicts |> list.first |> result.unwrap(dict.new())
  head |> distro_from_dict
}

pub fn distro_from_dict(dict) {
  let ascap = #(Ascap, ["Statement Recipient Name", "Party Name"])
  let vydia = #(Vydia, ["Balance Adjustment ID"])
  let distrokid = #(Distrokid, ["Team Percentage", "Song/Album"])
  let songtrust = #(Songtrust, ["royalty_type", "amount_received"])
  let sound_exchange = #(SoundExchange, ["Royalty Item SXID"])
  let mlc = #(MLC, ["Member MLC Number"])
  let bmi = #(BMI, ["Royalty Amt"])

  check_distros(dict, [
    ascap,
    vydia,
    distrokid,
    songtrust,
    sound_exchange,
    mlc,
    bmi,
  ])
}

// TODO: check that this works with multiple headers
fn check_distros(dict, distros: List(#(Distributor, List(String)))) {
  case
    distros
    |> list.find(fn(l) {
      let #(_, headers) = l
      dict |> dict_contains(headers)
    })
  {
    Ok(#(distro, _)) -> Some(distro)
    Error(_) -> None
  }
}

fn dict_contains(d, headers) {
  case headers {
    [] -> True
    [first, ..rest] -> {
      case d |> dict.has_key(first) {
        False -> False
        True -> dict_contains(d, rest)
      }
    }
  }
}

pub fn headers_from_distro(distro) {
  case distro {
    Ascap -> ascap.headers()
    Vydia -> vydia.headers()
    Distrokid -> distrokid.headers()
    SoundExchange -> soundexchange.headers()
    Songtrust -> songtrust.headers()
    MLC -> mlc.headers()
    BMI -> panic as "not implemented"
    _ -> globals.headers()
  }
}
