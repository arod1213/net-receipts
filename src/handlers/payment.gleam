import database/transaction
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/result
import models/payment
import services/payment_service
import sql/payment as sql_pay
import wisp

pub fn get_by_title(db, title) {
  case sql_pay.get_by_title(db, title, None) {
    Ok(p) -> {
      let res = p |> json.array(fn(x) { x |> payment.encoder })
      wisp.json_response(res |> json.to_string, 200)
    }
    Error(e) -> {
      echo e as "SQL ERROR"
      wisp.bad_request("No results")
    }
  }
}

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

pub fn save_csv(req: wisp.Request, db) {
  use form <- wisp.require_form(req)

  // TODO: save per read to reduce memory
  // TODO: create batch save method to increase efficiency on save
  let res =
    form.files
    |> list.filter_map(fn(x) {
      let #(_, file) = x
      case payment_service.file_to_payments(file.path) {
        Ok(p) -> {
          list.sized_chunk(p, 6000)
          |> list.try_each(fn(x) {
            transaction.start(db)
            let x = payment.save_many(db, x)
            transaction.commit_or_roll(db, x)
            |> result.map_error(fn(_) { Nil })
          })
        }
        Error(_) -> {
          Error(Nil)
        }
      }
    })

  // TODO get count of new payments
  case res |> list.length {
    0 -> {
      wisp.bad_request("Failed to save")
    }
    _ -> wisp.accepted()
  }
}
