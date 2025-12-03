import envoy
import gleam/erlang/process.{type Name}
import gleam/otp/static_supervisor
import gleam/result
import pog

pub fn read_connection_uri(name: Name(pog.Message)) {
  let url =
    envoy.get("DATABASE_URL")
    |> result.unwrap("postgresql://aidan@localhost:5432/royalties")
  echo url as "URL"
  let assert Ok(config) = pog.url_config(name, url)
  config |> pog.pool_size(15) |> pog.supervised
}

pub fn start_application_supervisor(name) {
  let url =
    envoy.get("DATABASE_URL")
    |> result.unwrap("postgresql://aidan@localhost:5432/royalties")
  echo url as "URL"
  let assert Ok(config) = pog.url_config(name, url)

  let pool_child =
    config
    |> pog.pool_size(15)
    |> pog.supervised

  static_supervisor.new(static_supervisor.RestForOne)
  |> static_supervisor.add(pool_child)
  |> static_supervisor.start
}
