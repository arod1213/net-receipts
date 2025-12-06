import gleam/dict
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import http/utils
import models/song
import services/payment_service
import sql/payment as sql_pay
import tempo/date
import utils/fuzz
import wisp

pub fn get_by_date(db, date) {
  // use d <- result.try(
  //   date |> date.from_string |> result.map(fn(x) { x |> date.to_calendar_date }),
  // )
  let assert Ok(d) =
    date |> date.from_string |> result.map(fn(x) { x |> date.to_calendar_date })

  case sql_pay.get_by_date(db, d) {
    Ok(p) -> {
      let songs = p |> song.songs_from_payments
      let res = songs |> json.array(fn(x) { x |> song.encoder })
      wisp.json_response(res |> json.to_string, 200)
    }
    Error(_) -> wisp.bad_request("No results")
  }
}

pub fn get_by_title(req: wisp.Request, db, title) {
  let q = case req.query {
    Some(s) -> s |> utils.query_to_dict
    None -> dict.new()
  }

  let title = title |> uri.percent_decode |> result.unwrap("")
  let payor =
    case q |> dict.get("payor") {
      Ok(s) -> s |> uri.percent_decode
      x -> x
    }
    |> option.from_result

  case sql_pay.get_by_title(db, title, payor) {
    Ok(p) -> {
      let songs = p |> song.songs_from_payments
      let res = songs |> json.array(fn(x) { x |> song.encoder })
      wisp.json_response(res |> json.to_string, 200)
    }
    Error(_) -> wisp.bad_request("No results")
  }
}

pub fn get_by_distro(db, distro) {
  let distro = distro |> uri.percent_decode |> result.unwrap("")
  case sql_pay.get_by_distro(db, distro) {
    Ok(p) -> {
      let songs = p |> song.songs_from_payments
      let res = songs |> json.array(fn(x) { x |> song.encoder_simple })
      wisp.json_response(res |> json.to_string, 200)
    }
    Error(_) -> wisp.bad_request("No results")
  }
}

pub fn read_csv(req: wisp.Request) {
  use form <- wisp.require_form(req)

  let payments =
    form.files
    |> list.filter_map(fn(x) {
      let #(_, file) = x
      payment_service.file_to_payments(file.path)
    })
    |> list.flatten

  let songs =
    payments
    |> song.songs_from_payments
    |> song.sort_by_earnings

  let overview =
    song.Song(
      title: "Overview",
      artist: None,
      isrc: None,
      iswc: None,
      upc: None,
      payments: payments,
    )

  let json_res =
    json.object([
      #("songs", json.array(songs, fn(s) { s |> song.encoder })),
      #("overview", overview |> song.encoder),
    ])
    |> json.to_string

  wisp.json_response(json_res, 200)
}

pub fn read_csv_song(req: wisp.Request, title) {
  use form <- wisp.require_form(req)
  let title = uri.percent_decode(title) |> result.unwrap("")

  let payments =
    form.files
    |> list.filter_map(fn(x) {
      let #(_, file) = x
      payment_service.file_to_payments(file.path)
      |> result.map(fn(x) {
        x
        |> list.filter(fn(pay) { fuzz.strings_are_equivalent(pay.title, title) })
      })
    })
    |> list.flatten

  let songs = payments |> song.songs_from_payments |> song.sort_by_earnings

  case songs |> list.length {
    0 -> wisp.json_response("{'error': 'no entries found'}", 401)
    _ -> {
      let text =
        json.array(songs, fn(s) { s |> song.encoder_simple })
        |> json.to_string

      wisp.json_response(text, 200)
    }
  }
}
