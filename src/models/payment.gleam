import decoders.{decode_one_field, float_decoder}
import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import models/header
import models/payor.{type Payor}
import pog
import tempo
import tempo/date
import utils/hash

pub type Payment {
  Payment(
    hash: String,
    id: String,
    earnings: Float,
    payor: Payor,
    artist: Option(String),
    title: String,
    isrc: Option(String),
    iswc: Option(String),
    upc: Option(Int),
    date: Option(tempo.Date),
    territory: Option(String),
  )
}

pub fn save(db, payment: Payment) {
  let query =
    "
INSERT INTO payments (
  unique_id, id, earnings, payor, title, artist, isrc, iswc, territory, date
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    "

  pog.query(query)
  |> pog.parameter(pog.text(payment.hash))
  |> pog.parameter(pog.text(payment.id))
  |> pog.parameter(pog.float(payment.earnings))
  |> pog.parameter(pog.text(payment.payor |> payor.to_string))
  |> pog.parameter(pog.text(payment.title))
  |> pog.parameter(pog.nullable(fn(x) { pog.text(x) }, payment.artist))
  |> pog.parameter(pog.nullable(fn(x) { pog.text(x) }, payment.isrc))
  |> pog.parameter(pog.nullable(fn(x) { pog.text(x) }, payment.isrc))
  |> pog.parameter(pog.nullable(fn(x) { pog.text(x) }, payment.territory))
  |> pog.parameter(pog.nullable(
    fn(x) { pog.calendar_date(x) },
    payment.date |> option.map(fn(x) { x |> date.to_calendar_date }),
  ))
  |> pog.execute(db)
}

pub fn sql_decoder() {
  use hash <- decode.field(0, decode.string)
  use id <- decode.field(1, decode.string)
  use earnings <- decode.field(2, float_decoder())
  use payor <- decode.field(3, payor.decoder())
  use title <- decode.field(4, decode.string)
  use artist <- decode.field(5, decode.optional(decode.string))
  use isrc <- decode.field(6, decode.optional(decode.string))
  use iswc <- decode.field(7, decode.optional(decode.string))
  use upc <- decode.field(8, decode.optional(decode.int))
  use territory <- decode.field(9, decode.optional(decode.string))
  use date <- decode.field(10, decode.optional(pog.calendar_date_decoder()))
  let date = case date {
    Some(s) -> date.from_calendar_date(s) |> option.from_result
    None -> None
  }

  decode.success(Payment(
    hash:,
    id:,
    isrc:,
    iswc:,
    upc:,
    artist:,
    earnings:,
    title:,
    payor:,
    territory:,
    date:,
  ))
}

pub fn decoder() -> decode.Decoder(Payment) {
  use isrc <- decode.field("isrc", decode.optional(decode.string))
  use iswc <- decode.field("iswc", decode.optional(decode.string))
  use id <- decode.field("unique_id", decode.string)
  use date <- decode.field("date", decoders.date_decoder())
  use payor <- decode.field("payor", payor.decoder())
  use upc <- decode.field("upc", decode.optional(decode.int))

  use title <- decode.field("title", decode.string)
  use artist <- decode.field("artist", decode.optional(decode.string))
  use territory <- decode.field("territory", decode.optional(decode.string))
  use earnings <- decode.field("earnings", float_decoder())
  use hash <- decode.field("hash", decode.string)

  decode.success(Payment(
    hash:,
    id:,
    isrc:,
    iswc:,
    upc:,
    artist:,
    earnings:,
    title:,
    payor:,
    territory:,
    date:,
  ))
}

pub fn encoder(p: Payment) -> Json {
  json.object([
    #("isrc", json.nullable(p.isrc, json.string)),
    #("iswc", json.nullable(p.iswc, json.string)),
    #("date", json.nullable(p.date, decoders.date_to_json)),
    #("payor", p.payor |> payor.encoder),
    #("upc", json.nullable(p.upc, json.int)),
    #("territory", json.nullable(p.territory, json.string)),
    #("title", json.string(p.title)),
    #("artist", json.nullable(p.artist, json.string)),
    #("earnings", json.float(p.earnings)),
  ])
}

pub fn decoder_dict(data, payor, header: header.Header) {
  let hash = hash.hash_csv(data)

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

  // TODO: Check description to check if entry is a withdrawal
  use <- bool.guard(earnings <. -1.0, Error(decoders.Withdrawal))

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

  let territory =
    data
    |> decode_one_field(header.territory, fn(x) { Ok(x |> string.trim) })
    |> option.from_result
  // TODO: implement custom decoders based on payor
  let date =
    data
    |> decode_one_field(header.dates, fn(x) {
      date.parse_any(x) |> result.map_error(fn(_) { Nil })
    })
    |> option.from_result

  Ok(Payment(
    hash:,
    id:,
    iswc:,
    isrc:,
    upc:,
    artist:,
    earnings:,
    title:,
    payor:,
    territory:,
    date:,
  ))
}

// reduce multiple iterations to calculate overviews
pub fn get_details(payments: List(Payment)) {
  let #(by_date, payor, territory) =
    payments
    |> list.fold(#(dict.new(), dict.new(), dict.new()), fn(acc, x) {
      let #(by_date, payor, territory) = acc
      let territory = save_territory(territory, x)
      let by_date = save_date(by_date, x)
      let payor = save_payor(payor, x)
      #(by_date, payor, territory)
    })

  let by_date = by_date |> sort_date
  let payor = payor |> dict.values
  let territory = territory |> sort_territory
  #(by_date, payor, territory)
}

fn save_date(acc, x: Payment) {
  case x.date {
    Some(key) -> {
      let normalized_date = date.first_of_month(key)
      let payments = case acc |> dict.get(normalized_date) {
        Ok(s) -> s +. x.earnings
        Error(_) -> x.earnings
      }
      acc |> dict.insert(normalized_date, payments)
    }
    None -> acc
  }
}

fn sort_date(acc) {
  acc
  |> dict.to_list
  |> list.sort(fn(a, b) {
    let #(a_date, _) = a
    let #(b_date, _) = b
    date.compare(a_date, b_date)
  })
}

pub fn earnings_by_date(vals: List(Payment)) {
  vals
  |> list.fold(dict.new(), fn(acc, x) { save_date(acc, x) })
  |> sort_date
}

fn save_payor(acc, x: Payment) {
  let key = x.payor
  let payment = case acc |> dict.get(key) {
    Ok(s) -> converge(s, x)
    Error(_) -> x
  }
  acc |> dict.insert(key, payment)
}

// payments from same song -> converge by distributor
pub fn converge_by_payor(vals: List(Payment)) -> List(Payment) {
  list.fold(vals, dict.new(), fn(acc, x) { save_payor(acc, x) })
  |> dict.values
}

pub fn converge_list(vals: List(Payment)) {
  vals
  |> list.reduce(fn(acc, x) { converge(acc, x) })
}

fn converge(a: Payment, b: Payment) {
  let id = a.id
  let hash = a.hash
  let title = a.title
  let territory = a.territory
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

  let payor = case a.payor {
    payor.Unknown -> b.payor
    _ -> a.payor
  }

  Payment(
    hash:,
    id:,
    iswc:,
    isrc:,
    upc:,
    artist:,
    title:,
    earnings:,
    payor:,
    date:,
    territory:,
  )
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

fn save_territory(acc, x: Payment) {
  case x.territory {
    Some(key) -> {
      let sum = case acc |> dict.get(key) {
        Ok(s) -> converge(s, x)
        Error(_) -> x
      }
      dict.insert(acc, key, sum)
    }
    None -> acc
  }
}

fn sort_territory(acc) {
  acc
  |> dict.values
  |> list.sort(fn(a: Payment, b: Payment) {
    float.compare(b.earnings, a.earnings)
  })
  |> list.take(5)
}

pub fn converge_by_territory(payments: List(Payment)) {
  payments
  |> list.fold(dict.new(), fn(acc, x) { save_territory(acc, x) })
  |> sort_territory
}
