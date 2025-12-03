import pog

pub fn migrate(db) {
  let sql_query =
    "
  CREATE TABLE IF NOT EXISTS payments (
    unique_id TEXT PRIMARY KEY NOT NULL,
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
  pog.query(sql_query)
  |> pog.execute(db)
}
