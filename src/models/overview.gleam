import gleam/json
import gleam/list
import models/payment.{type Payment}
import models/payor.{type Payor}
import tempo
import tempo/date

pub type KeyType {
  Payor(Payor)
  Date(tempo.Date)
}

pub type Overview {
  Overview(key: KeyType, earnings: Float)
}

fn encoder(overview: Overview) {
  case overview.key {
    Payor(d) -> {
      json.object([
        #("payor", d |> payor.encoder),
        #("earnings", overview.earnings |> json.float),
      ])
    }
    Date(date) -> {
      json.object([
        #("date", date |> date.to_string |> json.string),
        #("earnings", overview.earnings |> json.float),
      ])
    }
  }
}

pub fn encode_from_payments(payments: List(Payment)) {
  payments
  |> list.map(fn(x) {
    Overview(key: Payor(x.payor), earnings: x.earnings) |> encoder
  })
}

pub fn encode_from_growth(growth_info: List(#(tempo.Date, Float))) {
  growth_info
  |> list.map(fn(x) {
    let #(date, total) = x
    Overview(key: Date(date), earnings: total) |> encoder
  })
}
