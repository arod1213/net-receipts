import gleam/option.{type Option, None, Some}
import gleam/result
import models/song
import pog

pub fn get_first(db) {
  let query = "SELECT * FROM songs LIMIT 1"

  let x =
    pog.query(query)
    |> pog.returning(song.sql_decoder())
    |> pog.execute(db)
    |> result.map(fn(x) { x.rows })
  case x {
    Error(e) -> {
      echo e as "DECODE ERROR"
      x
    }
    x -> x
  }
}
