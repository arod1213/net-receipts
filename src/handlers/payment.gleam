import db
import gleam/bool
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import models/payment
import services/payment_service
import sqlight
import wisp

pub fn read_csv(req: wisp.Request) {
  use form <- wisp.require_form(req)

  let payments =
    form.files
    |> list.filter_map(fn(x) {
      let #(_, file) = x
      payment_service.file_to_payments(file.path)
    })
    |> list.flatten
    |> payment.sort

  case payments |> list.length {
    0 -> wisp.json_response("{'error': 'unsupported data type'}", 401)
    _ -> {
      let text =
        json.array(payments, fn(s) { s |> payment.encoder })
        |> json.to_string

      wisp.json_response(text, 200)
    }
  }
}

pub fn enrich(_req, conn) {
  let titles = payment_service.unique_titles(conn) |> result.unwrap([])

  case enrich_priv(conn, titles) {
    Ok(_) -> wisp.json_response("{'success': 'songs enriched'}", 200)
    Error(_) -> wisp.bad_request("Could not be enriched")
  }
}

fn enrich_priv(conn: sqlight.Connection, titles: List(String)) {
  list.try_each(titles, fn(title) {
    use entries <- result.try(
      payment_service.select_all(conn, title) |> result.map_error(fn(_) { Nil }),
    )
    use entry <- result.try(payment.converge_list(entries))

    let sql = "UPDATE payments SET isrc = ?1, upc = ?2 WHERE title = ?3"
    let values = [
      sqlight.nullable(sqlight.text, entry.isrc),
      sqlight.nullable(sqlight.int, entry.upc),
      sqlight.text(title),
    ]

    db.insert(conn, sql, values, decode.success(""))
    |> result.map_error(fn(_) { Nil })
  })
}

pub fn save_csv(req: wisp.Request, conn: sqlight.Connection) {
  use form <- wisp.require_form(req)

  let payments =
    form.files
    |> list.filter_map(fn(x) {
      case x {
        #(_, file) -> payment_service.file_to_payments(file.path)
      }
    })
    |> list.flatten

  use <- bool.lazy_guard(payments == [], fn() {
    wisp.bad_request("no files sent")
  })

  case payment_service.insert_payments(conn, payments) {
    Ok(_) -> {
      echo "INSERT SUCCEEDED"
      wisp.accepted()
    }
    Error(_) -> {
      echo "FAILED TO INSERT"
      wisp.bad_request("Payments could not be saved")
    }
  }
}
