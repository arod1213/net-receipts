import cors_builder as cors
import envoy
import gleam/result

import gleam/erlang/process
import gleam/http
import handlers/payment
import handlers/song
import mist

import wisp.{type Response}
import wisp/wisp_mist

pub fn blank(_req) -> wisp.Response {
  wisp.json_response("welcome to auditor", 200)
}

fn cors() {
  cors.new()
  |> cors.allow_origin("https://net-receipts-web.vercel.app")
  |> cors.allow_origin("http://localhost:5173")
  |> cors.allow_header("Content-Type")
  |> cors.allow_method(http.Options)
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

pub fn handle_request(req) -> Response {
  use req <- cors.wisp_middleware(req, cors())
  case wisp.path_segments(req) {
    [] -> blank(req)
    ["read", "payment"] -> payment.read_csv(req)
    ["read", "song"] -> song.read_csv(req)
    ["read", "song", title] -> song.read_csv_song(req, title)
    _ -> wisp.not_found()
  }
}

pub fn main() {
  wisp.configure_logger()
  // let conn = db.establish_conn("test.db")
  let secret_key_base =
    envoy.get("FLY_API_TOKEN") |> result.unwrap("secret_key")

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
