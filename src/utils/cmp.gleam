pub fn max(a, b) {
  case a > b {
    True -> a
    False -> b
  }
}

pub fn min(a, b) {
  case a < b {
    True -> a
    False -> b
  }
}
