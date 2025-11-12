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
import providers/onerpm
import providers/songtrust
import providers/soundexchange
import providers/vydia

pub type Payor {
  Vydia
  Ascap
  BMI
  Songtrust
  Distrokid
  SoundExchange
  MLC
  OneRPM
  Unknown
}

pub type IncomeType {
  Master
  Publishing
  Performance
  Mechanical
}

pub fn income_type(payor) {
  case payor {
    Vydia | Distrokid | SoundExchange | OneRPM -> Some(Master)
    Ascap | BMI -> Some(Performance)
    Songtrust -> Some(Publishing)
    MLC -> Some(Mechanical)
    _ -> None
  }
}

fn income_type_to_string(i) {
  case i {
    Master -> "Master"
    Publishing -> "Publishing"
    Mechanical -> "Mechanical"
    Performance -> "Performance"
  }
}

pub fn decoder() {
  decode.then(decode.string, fn(a) {
    case a {
      "Vydia" -> decode.success(Vydia)
      "OneRPM" -> decode.success(OneRPM)
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

pub fn to_string(d: Payor) -> String {
  case d {
    OneRPM -> "OneRPM"
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

pub fn encoder(d: Payor) -> Json {
  json.object([
    #("name", d |> to_string |> json.string),
    #(
      "type",
      json.nullable(
        d |> income_type |> option.map(income_type_to_string),
        fn(x) { x |> json.string },
      ),
    ),
  ])
}

pub fn payor_from_data(data: String, sep: String) -> option.Option(Payor) {
  let dicts = data |> gsv.to_dicts(sep) |> result.unwrap([])
  let head = dicts |> list.first |> result.unwrap(dict.new())
  head |> payor_from_dict
}

pub fn payor_from_dict(dict) {
  let ascap = #(Ascap, ["Statement Recipient Name", "Party Name"])
  let vydia = #(Vydia, ["Balance Adjustment ID"])
  let distrokid = #(Distrokid, ["Team Percentage", "Song/Album"])
  let songtrust = #(Songtrust, ["royalty_type", "amount_received"])
  let sound_exchange = #(SoundExchange, ["Royalty Item SXID"])
  let mlc = #(MLC, ["Member MLC Number"])

  // TODO: double check this
  let onerpm = #(OneRPM, ["Album/Channel", "Source Account"])

  let bmi = #(BMI, ["Royalty Amt"])

  check_payors(dict, [
    ascap,
    vydia,
    distrokid,
    songtrust,
    sound_exchange,
    mlc,
    onerpm,
    bmi,
  ])
}

// TODO: check that this works with multiple headers
fn check_payors(dict, payors: List(#(Payor, List(String)))) {
  case
    payors
    |> list.find(fn(l) {
      let #(_, headers) = l
      dict |> dict_contains(headers)
    })
  {
    Ok(#(payor, _)) -> Some(payor)
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

pub fn headers_from_payor(payor) {
  case payor {
    Ascap -> ascap.headers()
    Vydia -> vydia.headers()
    Distrokid -> distrokid.headers()
    SoundExchange -> soundexchange.headers()
    Songtrust -> songtrust.headers()
    MLC -> mlc.headers()
    OneRPM -> onerpm.headers()
    BMI -> panic as "not implemented"
    _ -> globals.headers()
  }
}
