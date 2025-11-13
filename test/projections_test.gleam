import gleam/option.{Some}
import services/projections

// TODO: review this and actually write a good projection thereom
pub fn project_test() {
  let a = [100.0, 200.0, 300.0, 400.0]
  let answer = projections.estimate_royalties(a)
  echo answer
  assert Some(325.0) == answer

  let a = [100.0, 200.0, 300.0, 200.0, 100.0]
  let answer = projections.estimate_royalties(a)
  echo answer
  assert Some(180.0) == answer
}
