import gleam/result
import models/payment
import pog

pub fn get_by_title(db, title) {
  let query = "SELECT * FROM payments WHERE TITLE ILIKE $1"

  pog.query(query)
  |> pog.parameter(pog.text("%" <> title <> "%"))
  |> pog.returning(payment.sql_decoder())
  |> pog.execute(db)
  |> result.map(fn(x) { x.rows })
}
