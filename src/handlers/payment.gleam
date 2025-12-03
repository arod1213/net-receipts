import gleam/json
import gleam/list
import models/payment
import services/payment_service
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

pub fn save_csv(req: wisp.Request, db) {
  use form <- wisp.require_form(req)

  // TODO: save per read to reduce memory
  let res =
    form.files
    |> list.filter_map(fn(x) {
      let #(_, file) = x
      payment_service.file_to_payments(file.path)
    })
    |> list.flatten
    |> list.try_each(fn(x) { payment.save(db, x) })

  // TODO get count of new payments
  case res {
    Ok(_) -> wisp.accepted()
    Error(_) -> wisp.bad_request("Failed to save")
  }
}
