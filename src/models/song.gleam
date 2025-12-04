import gleam/dict
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None}
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import models/overview
import models/payment.{type Payment}
import services/projections
import utils/fuzz

pub type Song {
  Song(
    title: String,
    artist: Option(String),
    isrc: Option(String),
    iswc: Option(String),
    upc: Option(Int),
    payments: List(Payment),
  )
}

pub fn encoder(s: Song) -> Json {
  let #(pay_by_date, payor_data, territory_data) =
    s.payments |> payment.get_details
  let growth_data = overview.encode_from_growth(pay_by_date)
  let payor_data = payor_data |> overview.encode_from_payments
  let territory_data = territory_data |> overview.encode_from_territory

  let projection = projections.estimate_royalties(pay_by_date)

  json.object([
    #("title", s.title |> json.string),
    #("artist", json.nullable(s.artist, json.string)),

    // #("payments", json.array(s.payments, payment.encoder)),
    #("projection", json.nullable(projection, json.float)),

    #("isrc", json.nullable(s.isrc, json.string)),
    #("iswc", json.nullable(s.iswc, json.string)),
    #("upc", json.nullable(s.upc, json.int)),
    #("growth", json.array(growth_data, fn(x) { x })),
    #("payors", json.array(payor_data, fn(x) { x })),
    #("territories", json.array(territory_data, fn(x) { x })),
    #(
      "total",
      json.float(s.payments |> list.fold(0.0, fn(acc, x) { x.earnings +. acc })),
    ),
  ])
}

pub fn encoder_simple(s: Song) -> Json {
  json.object([
    #("title", s.title |> json.string),
    #("artist", json.nullable(s.artist, json.string)),
    #("isrc", json.nullable(s.isrc, json.string)),
    #("iswc", json.nullable(s.iswc, json.string)),
    #("upc", json.nullable(s.upc, json.int)),
    #(
      "total",
      json.float(s.payments |> list.fold(0.0, fn(acc, x) { x.earnings +. acc })),
    ),
  ])
}

fn matching_title(titles: List(String), needle: String) -> Result(String, Nil) {
  titles
  |> list.find(fn(x) {
    let len = int.min(string.length(x), string.length(needle))
    case len > 5 {
      False -> False
      True -> fuzz.strings_are_equivalent(x, needle)
    }
  })
}

// TODO: get most common artist name and insert that instead of first
pub fn songs_from_payments(payments: List(Payment)) -> List(Song) {
  payments
  |> group_by_title
  |> dict.map_values(grouped_to_song)
  |> dict.values
}

fn group_by_title(payments: List(Payment)) {
  payments
  |> list.fold(#(dict.new(), dict.new()), fn(accrued, pay) {
    let #(acc, cache) = accrued

    let #(key, cache) = case dict.get(cache, pay.title) {
      Ok(normalized) -> #(normalized, cache)
      Error(_) -> {
        let normalized =
          matching_title(acc |> dict.keys, pay.title)
          |> result.unwrap(pay.title)
        #(normalized, cache |> dict.insert(pay.title, normalized))
      }
    }

    let vals = case dict.get(acc, key) {
      Ok(s) -> [pay, ..s]
      Error(_) -> [pay]
    }

    #(dict.insert(acc, key, vals), cache)
  })
  |> pair.first
}

fn grouped_to_song(title, vals: List(Payment)) {
  let artist =
    fuzz.most_common_entry(
      list.filter_map(vals, fn(x) { x.artist |> option.to_result(Nil) }),
    )
    |> option.from_result

  // TODO: see how removing this impacts performance
  // let vals = vals |> payment.converge_by_distro

  let #(iswc, isrc, upc) =
    vals
    |> list.fold_until(#(None, None, None), fn(acc, p) {
      let #(iswc_acc, isrc_acc, upc_acc) = acc

      let iswc_new = option.or(iswc_acc, p.iswc)
      let isrc_new = option.or(isrc_acc, p.isrc)
      let upc_new = option.or(upc_acc, p.upc)

      case acc {
        #(None, _, _) | #(_, None, _) | #(_, _, None) ->
          list.Continue(#(iswc_new, isrc_new, upc_new))
        x -> list.Stop(x)
      }
    })
  Song(title:, iswc:, payments: vals, isrc:, upc:, artist:)
}

pub fn sort_by_earnings(songs: List(Song)) {
  songs
  |> list.sort(fn(a, b) {
    let a_sum = a.payments |> payment.total
    let b_sum = b.payments |> payment.total
    case a_sum >. b_sum {
      True -> order.Lt
      False -> order.Gt
    }
  })
}
