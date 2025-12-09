import utils/territory

pub fn case_test() {
  let a = "united states"
  assert territory.standard_case(a) == "United States"
}
