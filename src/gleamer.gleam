import cors_builder as cors

// import db
import gleam/erlang/process
import gleam/http
import handlers/payment
import handlers/song
import mist

// import sqlight
import wisp.{type Response}
import wisp/wisp_mist

pub fn blank(_req) -> wisp.Response {
  wisp.json_response("welcome to auditor", 200)
}

fn cors() {
  cors.new()
  |> cors.allow_origin("http://localhost:5173")
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
    // ["enrich", "payment"] -> payment.enrich(req, conn)
    // ["save"] -> payment.save_csv(req, conn)
    _ -> wisp.not_found()
  }
}

pub fn main() {
  wisp.configure_logger()
  // let conn = db.establish_conn("test.db")

  let assert Ok(_) =
    wisp_mist.handler(handle_request, "secret_key")
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
