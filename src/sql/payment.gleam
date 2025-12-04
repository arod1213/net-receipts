import gleam/option.{type Option, None, Some}
import gleam/result
import models/payment
import models/payor
import pog

pub fn get_by_title(db, title, payor: Option(String)) {
  let query = "SELECT * FROM payments WHERE title ILIKE $1 "

  let query = case payor {
    Some(s) -> query <> "AND payor ILIKE " <> "'%" <> s <> "%' "
    None -> query
  }

  let query = query <> "ORDER BY earnings DESC"

  pog.query(query)
  |> pog.parameter(pog.text("%" <> title <> "%"))
  |> pog.returning(payment.sql_decoder())
  |> pog.execute(db)
  |> result.map(fn(x) { x.rows })
}

pub fn get_by_distro(db, distro) {
  let query =
    "SELECT * FROM payments WHERE payor ILIKE $1 ORDER BY earnings DESC"

  pog.query(query)
  |> pog.parameter(pog.text("%" <> distro <> "%"))
  |> pog.returning(payment.sql_decoder())
  |> pog.execute(db)
  |> result.map(fn(x) { x.rows })
}
