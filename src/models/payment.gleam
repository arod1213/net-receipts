import db
import decoders.{decode_one_field, float_decoder}
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import models/distro.{type Distributor}
import models/header
import sqlight
import tempo
import tempo/date
import utils/errors

pub type Payment {
  Payment(
    id: String,
    earnings: Float,
    distro: Distributor,
    artist: Option(String),
    title: String,
    isrc: Option(String),
    iswc: Option(String),
    upc: Option(Int),
    date: Option(tempo.Date),
  )
}

pub fn insert(conn: sqlight.Connection, p: Payment) {
  let sql =
    "insert into payments 
    (unique_id, earnings, distro, artist, title, isrc, upc, date)
    values (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
  "
  let args = [
    sqlight.text(p.id),
    sqlight.float(p.earnings),
    sqlight.text(p.distro |> distro.to_string),
    sqlight.nullable(sqlight.text, p.artist),
    sqlight.text(p.title),
    sqlight.nullable(sqlight.text, p.isrc),
    sqlight.nullable(sqlight.int, p.upc),
    sqlight.nullable(
      fn(date) { date |> decoders.date_to_string |> sqlight.text },
      p.date,
    ),
  ]
  db.insert(conn, sql, args, decode.success(""))
}

pub fn decode_sql() -> decode.Decoder(Payment) {
  // use id <- decode.field(1, decode.int)
  use id <- decode.field(1, decode.string)
  // use date <- decode.field(2, decode.optional(decoders.date_decoder))
  use title <- decode.field(3, decode.string)
  use artist <- decode.field(4, decode.optional(decode.string))
  use earnings <- decode.field(5, float_decoder())
  use distro <- decode.field(6, distro.decoder())
  use isrc <- decode.field(7, decode.optional(decode.string))
  use upc <- decode.field(8, decode.optional(decode.int))
  use iswc <- decode.field(9, decode.optional(decode.string))

  decode.success(Payment(
    id:,
    isrc:,
    iswc:,
    upc:,
    artist:,
    earnings:,
    title:,
    distro:,
    date: None,
  ))
}

pub fn decoder() -> decode.Decoder(Payment) {
  use isrc <- decode.field("isrc", decode.optional(decode.string))
  use iswc <- decode.field("iswc", decode.optional(decode.string))
  use id <- decode.field("unique_id", decode.string)
  use date <- decode.field("date", decoders.date_decoder())
  use distro <- decode.field("distro", distro.decoder())
  use upc <- decode.field("upc", decode.optional(decode.int))

  use title <- decode.field("title", decode.string)
  use artist <- decode.field("artist", decode.optional(decode.string))
  use earnings <- decode.field("earnings", float_decoder())

  decode.success(Payment(
    id:,
    isrc:,
    iswc:,
    upc:,
    artist:,
    earnings:,
    title:,
    distro:,
    date:,
  ))
}

pub fn encoder(p: Payment) -> Json {
  json.object([
    #("isrc", json.nullable(p.isrc, json.string)),
    #("iswc", json.nullable(p.iswc, json.string)),
    #("date", json.nullable(p.date, decoders.date_to_json)),
    #("distro", p.distro |> distro.encoder),
    #("upc", json.nullable(p.upc, json.int)),
    #("title", json.string(p.title)),
    #("artist", json.nullable(p.artist, json.string)),
    #("earnings", json.float(p.earnings)),
  ])
}

pub fn decoder_dict(data, distro, header: header.Header) {
  let id =
    data
    |> decode_one_field(header.id, fn(x) { Ok(x) })
    |> result.unwrap("unknown id")

  let isrc =
    data
    |> decode_one_field(header.isrcs, fn(x) {
      case string.trim(x) {
        "" -> Error(Nil)
        s -> Ok(s)
      }
    })
    |> option.from_result

  let iswc =
    data
    |> decode_one_field(header.iswcs, fn(x) {
      case string.trim(x) {
        "" -> Error(Nil)
        s -> Ok(s)
      }
    })
    |> option.from_result

  let upc =
    data |> decode_one_field(header.upcs, int.parse) |> option.from_result

  use earnings <- result.try(
    data |> decode_one_field(header.earnings, decoders.parse_clean_float),
  )

  let artist =
    data
    |> decode_one_field(header.artists, fn(x) {
      case string.trim(x) {
        "" -> Error(Nil)
        s -> Ok(s)
      }
    })
    |> option.from_result

  let title =
    data
    |> decode_one_field(header.titles, fn(x) { Ok(x |> string.trim) })
    |> result.unwrap("N/A")

  // TODO: implement custom decoders based on distro
  let date =
    data
    |> decode_one_field(header.dates, fn(x) {
      date.parse_any(x) |> errors.result_to_nil
    })
    |> errors.result_as_option

  Ok(Payment(
    id:,
    iswc:,
    isrc:,
    upc:,
    artist:,
    earnings:,
    title:,
    distro:,
    date:,
  ))
}

pub fn earnings_by_date(vals: List(Payment)) {
  vals
  |> list.fold(dict.new(), fn(acc, x) {
    case x.date {
      Some(key) -> {
        let payments = case acc |> dict.get(key) {
          Ok(s) -> s +. x.earnings
          Error(_) -> x.earnings
        }
        acc |> dict.insert(key, payments)
      }
      None -> acc
    }
  })
  |> dict.to_list
  |> list.sort(fn(a, b) {
    let #(a_date, _) = a
    let #(b_date, _) = b
    date.compare(a_date, b_date)
  })
}

// payments from same song -> converge by distributor
pub fn converge_by_distro(vals: List(Payment)) -> List(Payment) {
  list.fold(vals, dict.new(), fn(acc, x) {
    let key = x.distro
    let payment = case acc |> dict.get(key) {
      Ok(s) -> converge(s, x)
      Error(_) -> x
    }
    acc |> dict.insert(key, payment)
  })
  |> dict.values
}

pub fn converge_list(vals: List(Payment)) {
  vals
  |> list.reduce(fn(acc, x) { converge(acc, x) })
}

fn converge(a: Payment, b: Payment) {
  let id = a.id
  let title = a.title
  let earnings = a.earnings +. b.earnings
  let isrc = option.or(a.isrc, b.isrc)
  let iswc = option.or(a.iswc, b.iswc)
  let upc = option.or(a.upc, b.upc)
  let artist = option.or(a.artist, b.artist)

  // converging doesnt make sense here really
  let date = case a.date, b.date {
    Some(x), Some(y) -> {
      case x |> date.difference(from: y) > 0 {
        True -> Some(y)
        False -> Some(x)
      }
    }
    None, Some(x) -> Some(x)
    a, _ -> a
  }

  let distro = case a.distro {
    distro.Unknown -> b.distro
    _ -> a.distro
  }

  Payment(id:, iswc:, isrc:, upc:, artist:, title:, earnings:, distro:, date:)
}

pub fn total(payments: List(Payment)) {
  payments
  |> list.fold(0.0, fn(acc, x) { acc +. x.earnings })
}

pub fn sort(payments: List(Payment)) {
  payments
  |> list.sort(fn(a, b) {
    case a.earnings <. b.earnings {
      True -> order.Gt
      _ -> order.Lt
    }
  })
}

pub fn merge_sort(payments) {
  payments
  |> merge_payments_on_title
  |> sort
}

pub fn merge_payments_on_title(songs: List(Payment)) {
  let acc: dict.Dict(String, Payment) = dict.new()
  songs
  |> list.map(fn(x) { #(x.title, x) })
  |> list.fold(acc, fn(acc, x) {
    let #(k, v) = x
    case dict.get(acc, k) {
      Ok(p) -> {
        acc
        |> dict.insert(k, converge(v, p))
      }
      Error(_) -> acc |> dict.insert(k, v)
    }
  })
  |> dict.values
}
