import gleam/json
import gleam/list
import gleam/result
import gleam/uri
import models/song
import services/payment_service
import utils/fuzz
import wisp

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

  let text =
    json.array(songs, fn(s) { s |> song.encoder })
    |> json.to_string

  wisp.json_response(text, 200)
  // case songs |> list.length {
  //   0 -> wisp.json_response("{'error': 'unsupported data type'}", 401)
  //   _ -> {
  //     todo
  //   }
  // }
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
