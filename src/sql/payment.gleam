import gleam/result
import models/payment
import models/payor
import pog

pub fn get_by_title(db, title) {
  let query =
    "SELECT * FROM payments WHERE TITLE ILIKE $1 ORDER BY earnings DESC"

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
