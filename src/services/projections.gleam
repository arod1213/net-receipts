import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result

pub type Duration {
  Monthly
  BiAnnual
  Yearly
}

// fn since(d: Duration) {
//     let curr = tempo.now()
//     tempo.data_

//     // case d {
//     //     Monthly -> 
//     // }
// }

// ensure limited duration and ascending dates
// oldest first
// pub fn estimate_royalties(payments: List(Payment)) {
//   use <- bool.guard(payments |> list.length < 10, None)
//   todo
// }

fn mean(val: Float, len: Int) {
  use <- bool.guard(len == 0, 0.0)
  let len = len |> int.to_float
  val /. len
}

pub fn estimate_royalties(payments: List(Float)) {
  use <- bool.guard(payments |> list.length < 4, None)
  let avg =
    payments
    |> list.fold(0.0, fn(acc, x) { acc +. x })
    |> mean(payments |> list.length)

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
    Error(_) -> None
  }
}
