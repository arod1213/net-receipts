import utils/territory

pub fn case_test() {
  let a = "united states"
  assert territory.standard_case(a) == "United States"
}

pub fn territory_test() {
  let a = "united states"
  assert territory.territory_code_to_name(a) == "United States"
  let a = "UNITED STATES"
  assert territory.territory_code_to_name(a) == "United States"
}
