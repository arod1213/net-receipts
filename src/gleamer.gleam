import cors_builder as cors
import envoy
import gleam/result
import pog
import utils/env

import database/request
import database/setup
import gleam/erlang/process
import gleam/http
import handlers/payment
import handlers/song
import mist

import wisp.{type Response}
import wisp/wisp_mist

fn cors() {
  cors.new()
  |> cors.allow_origin("https://net-receipts-web.vercel.app")
  |> cors.allow_origin("http://localhost:5173")
  |> cors.allow_header("Content-Type")
  |> cors.allow_method(http.Options)
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
}

pub fn handle_request(req, db) -> Response {
  use <- wisp.log_request(req)
  use req <- cors.wisp_middleware(req, cors())

  case wisp.path_segments(req) {
    ["save"] -> payment.save_csv(req, db)

    ["get", "song", title] -> song.get_by_title(db, title)
    ["get", "distro", distro] -> song.get_by_distro(db, distro)
    ["get", "payment", title] -> payment.get_by_title(db, title)

    ["read", "payment"] -> payment.read_csv(req)
    ["read", "song"] -> song.read_csv(req)
    ["read", "song", title] -> song.read_csv_song(req, title)
    _ -> wisp.not_found()
  }
}

fn db_setup() {
  let p_name = process.new_name("database")
  let assert Ok(_) = setup.start_application_supervisor(p_name)
  let conn = pog.named_connection(p_name)
  let assert Ok(_) = request.migrate(conn)
  conn
}

pub fn main() {
  env.load_dotenv()
  let assert Ok(secret_key_base) = envoy.get("FLY_API_TOKEN")

  wisp.configure_logger()
  let conn = db_setup()

  let assert Ok(_) =
    wisp_mist.handler(handle_request(_, conn), secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
