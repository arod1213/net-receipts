import gleam/dynamic/decode
import gleam/option.{Some}
import gleam/result
import sqlight

pub fn val_or_null(val) {
  case val {
    Some(s) -> s
    _ -> "NULL"
  }
}

pub fn establish_conn(url) {
  case sqlight.open(url) {
    Ok(conn) -> {
      let assert Ok(Nil) = migrate(conn)
      conn
    }
    _ -> panic as "failed to conn to db"
  }
}

fn transaction_start(conn) {
  case
    sqlight.query(
      "BEGIN TRANSACTION",
      on: conn,
      with: [],
      expecting: decode.success(""),
    )
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(e)
  }
}

fn commit(conn) {
  case
    sqlight.query("COMMIT", on: conn, with: [], expecting: decode.success(""))
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(e)
  }
}

fn rollback(conn) {
  case
    sqlight.query("ROLLBACK", on: conn, with: [], expecting: decode.success(""))
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(e)
  }
}

pub fn transaction(conn, action) {
  use _ <- result.try(transaction_start(conn))

  case action(conn) {
    Ok(s) -> {
      use _ <- result.try(commit(conn))
      Ok(s)
    }
    Error(e) -> {
      use _ <- result.try(rollback(conn))
      Error(e)
    }
  }
}

// no return
pub fn insert(conn, sql: String, args: List(sqlight.Value), decoder) {
  case sqlight.query(sql, on: conn, with: args, expecting: decoder) {
    Ok(s) -> Ok(s)
    Error(e) -> Error(e)
  }
}

pub fn query(conn, sql, args, decoder) {
  sqlight.query(sql, on: conn, with: args, expecting: decoder)
}

// TODO: add unique contraints here
pub fn migrate(conn) {
  let sql =
    "
CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  unique_id TEXT NOT NULL,
  date TEXT,
  title TEXT NOT NULL,
  artist TEXT,
  earnings REAL NOT NULL,
  payor TEXT NOT NULL,
  isrc TEXT,
  upc INTEGER,
  UNIQUE (unique_id, earnings, distro, title)
);
  "
  let assert Ok(Nil) = sqlight.exec(sql, conn)
}
