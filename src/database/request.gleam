import gleam/result
import pog

pub fn migrate(db) {
  use _ <- result.try(
    "
  CREATE TABLE IF NOT EXISTS payments (
    unique_id BYTEA PRIMARY KEY NOT NULL,
    id TEXT NOT NULL,
    earnings REAL NOT NULL,
    payor TEXT NOT NULL,
    title TEXT NOT NULL,
    artist TEXT,
    isrc TEXT,
    iswc TEXT,
    upc INTEGER,
    territory TEXT,
    date DATE
  )
  "
    |> pog.query
    |> pog.execute(db),
  )

  "
  CREATE TABLE IF NOT EXISTS songs (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT,
    isrc TEXT,
    iswc TEXT,
    upc INTEGER
  )
  "
  |> pog.query
  |> pog.execute(db)
}
