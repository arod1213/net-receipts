import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import models/payor
import models/song
import services/payment_service
import sql/payment as sql_pay
import utils/fuzz
import utils/memory
import wisp

pub fn get_by_title(db, title) {
  case sql_pay.get_by_title(db, title) {
    Ok(p) -> {
      let songs = p |> song.songs_from_payments
      let res = songs |> json.array(fn(x) { x |> song.encoder })
      wisp.json_response(res |> json.to_string, 200)
    }
    Error(e) -> {
      echo e as "SQL ERROR"
      wisp.bad_request("No results")
    }
  }
}

pub fn get_by_distro(db, distro) {
  case sql_pay.get_by_distro(db, distro) {
    Ok(p) -> {
      echo p |> list.length as "Found"
      let songs = p |> song.songs_from_payments
      let res = songs |> json.array(fn(x) { x |> song.encoder_simple })
      wisp.json_response(res |> json.to_string, 200)
    }
    Error(e) -> {
      echo e as "SQL ERROR"
      wisp.bad_request("No results")
    }
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

  memory.log_memory("AFTER SCAN")

  let songs =
    payments
    |> song.songs_from_payments
    |> song.sort_by_earnings

  memory.log_memory("AFTER SONGS")
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

  memory.log_memory("AFTER JSON")
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
