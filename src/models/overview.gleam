import decoders
import gleam/json
import gleam/list
import gleam/option
import models/payment.{type Payment}
import models/payor.{type Payor}
import tempo
import utils/territory

pub type KeyType {
  Payor(Payor)
  Date(tempo.Date)
  Territory(String)
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
        #("date", date |> decoders.date_to_json),
        #("earnings", overview.earnings |> json.float),
      ])
    }
    Territory(territory) -> {
      json.object([
        #(
          "territory",
          territory |> territory.territory_code_to_name |> json.string,
        ),
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

pub fn encode_from_territory(payments: List(Payment)) {
  payments
  |> list.map(fn(x) {
    Overview(
      key: Territory(x.territory |> option.unwrap("N/A")),
      earnings: x.earnings,
    )
    |> encoder
  })
}

pub fn encode_from_growth(growth_info: List(#(tempo.Date, Float))) {
  growth_info
  |> list.map(fn(x) {
    let #(date, total) = x
    Overview(key: Date(date), earnings: total) |> encoder
  })
}
