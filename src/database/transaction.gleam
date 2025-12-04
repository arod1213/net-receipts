import gleam/result
import pog

pub fn wrap_write(conn, q) {
  let begin = pog.query("BEGIN")
  use _ <- result.try(pog.execute(begin, conn))

  case pog.execute(q, conn) {
    Ok(_) -> {
      let commit = pog.query("COMMIT")
      pog.execute(commit, conn)
    }
    Error(err) -> {
      let rollback = pog.query("ROLLBACK")
      use _ <- result.try(pog.execute(rollback, conn))
      Error(err)
    }
  }
}

pub fn start(conn) {
  let begin = pog.query("BEGIN")
  let assert Ok(x) = pog.execute(begin, conn)
  x
}

pub fn commit_or_roll(conn, x) {
  case x {
    Ok(_) -> {
      let commit = pog.query("COMMIT")
      pog.execute(commit, conn)
    }
    Error(err) -> {
      let rollback = pog.query("ROLLBACK")
      use _ <- result.try(pog.execute(rollback, conn))
      Error(err)
    }
  }
}
