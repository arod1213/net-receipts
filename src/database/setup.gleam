import envoy
import gleam/otp/static_supervisor
import gleam/result
import pog

pub fn start_application_supervisor(name) {
  let assert Ok(url) = envoy.get("DATABASE_URL")
  let assert Ok(config) = pog.url_config(name, url)

  let pool_child =
    config
    |> pog.pool_size(15)
    |> pog.supervised

  static_supervisor.new(static_supervisor.RestForOne)
  |> static_supervisor.add(pool_child)
  |> static_supervisor.start
}
