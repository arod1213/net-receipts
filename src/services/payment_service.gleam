import db
import gleam/dynamic/decode
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/result
import gleam/string
import gsv
import models/distro
import models/payment.{type Payment}
import simplifile
import sqlight

// DB stuff
pub fn insert_payments(conn: sqlight.Connection, payments: List(Payment)) {
  let inserts = fn(db_conn) {
    payments
    |> list.try_each(fn(x) {
      case payment.insert(db_conn, x) {
        Ok(_) -> Ok(Nil)
        Error(sqlight.SqlightError(sqlight.ConstraintUnique, _, _)) -> Ok(Nil)
        Error(e) -> Error(e)
      }
    })
  }
  db.transaction(conn, inserts)
}

pub fn select_all(conn, title) {
  let sql =
    "
  SELECT * FROM payments WHERE title = ?1;
  "
  let title = sqlight.text(title)
  db.query(conn, sql, [title], payment.decode_sql())
}

// FILE READ
pub type ReadError {
  MissingHeader
  FileError(simplifile.FileError)
  GsvError(gsv.Error)
  FileTypeError
}

pub fn file_to_payments(path: String) -> Result(List(Payment), ReadError) {
  use data <- result.try(
    simplifile.read(from: path) |> result.map_error(fn(e) { e |> FileError }),
  )

  use sep <- result.try(
    find_sep(data) |> result.map_error(fn(_) { FileTypeError }),
  )

  csv_decoder(data, sep)
}

pub fn csv_decoder(data, separator: String) {
  use dicts <- result.try(
    data
    |> gsv.to_dicts(separator:)
    |> result.map_error(fn(e) { GsvError(e) }),
  )

  use header <- result.try(
    dicts
    |> list.first
    |> result.map_error(fn(_) { MissingHeader }),
  )

  let distro = distro.distro_from_dict(header) |> option.unwrap(distro.Unknown)
  let headers = distro.headers_from_distro(distro)

  Ok(
    dicts
    |> list.filter_map(fn(dict) { payment.decoder_dict(dict, distro, headers) }),
  )
}

fn find_sep(data) {
  use line <- result.try(data |> string.split_once("\n"))
  let first = case line {
    #(a, _) -> a
  }

  let commas = #(",", first |> string.split(",") |> list.length)
  let tabs = #("\t", first |> string.split("\t") |> list.length)

  use #(sep, _) <- result.try(
    list.max([commas, tabs], fn(a, b) {
      let #(_, a_count) = a
      let #(_, b_count) = b

      case a_count > b_count {
        True -> order.Gt
        _ -> order.Lt
      }
    }),
  )
  Ok(sep)
}

// UTILS
pub fn unique_ids(payments: List(Payment)) {
  payments
  |> list.fold(#([], []), fn(acc, p) {
    let #(isrc, upc) = acc
    let a = case p.isrc {
      Some(s) -> [s, ..isrc]
      None -> isrc
    }
    let b = case p.upc {
      Some(s) -> [s, ..upc]
      None -> upc
    }
    #(a, b)
  })
}

pub fn unique_titles(conn) {
  let sql = "SELECT title FROM payments GROUP BY title"
  db.query(conn, sql, [], decode.list(decode.string))
  |> result.map(fn(a) { a |> list.flatten })
}
