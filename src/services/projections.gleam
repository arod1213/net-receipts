import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import models/payment.{type Payment}
import tempo
import tempo/date
import tempo/datetime
import tempo/duration
import tempo/instant

fn since(days: Int) {
  let curr = instant.now() |> instant.as_local_datetime
  let period = duration.days(days)
  datetime.subtract(curr, period) |> datetime.get_date
}

// ensure limited duration and ascending dates
// oldest first
// pub fn estimate_royalties(payments: List(Payment)) {
//   use <- bool.guard(payments |> list.length < 10, None)
//   todo
// }

fn mean(sum: Float, count: Int) {
  use <- bool.guard(count == 0, 0.0)
  let len = count |> int.to_float
  sum /. len
}

pub fn estimate_royalties(payments: List(#(tempo.Date, Float))) {
  let payments =
    payments
    |> list.filter(fn(x) {
      let #(pay_date, _) = x
      let since = since(180)
      date.difference(pay_date, since) < 0
    })
    |> list.map(fn(x) {
      let #(_, earnings) = x
      earnings
    })
  use <- bool.guard(payments |> list.length == 0, None)

  let avg =
    payments
    |> list.fold(0.0, fn(acc, x) { acc +. x })
    |> mean(payments |> list.length)

  // Some(avg)
  let slope =
    payments
    |> list.window_by_2
    |> list.map(fn(x) {
      let #(a, b) = x
      b -. a
    })
    |> list.reduce(fn(acc, slope) { acc +. slope })
    |> result.try(fn(x) {
      let len = payments |> list.length |> int.to_float
      Ok(x /. len)
    })

  case slope {
    Ok(s) -> Some(avg +. s)
    Error(_) -> Some(avg)
  }
}
