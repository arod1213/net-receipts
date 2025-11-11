import gleam/dict
import gleam/option.{Some}
import models/distro
import utils/fuzz

pub fn distro_from_dict_test() {
  let l = [#("Statement Recipient Name", 0), #("Work Title", 0)]
  let a = dict.from_list(l)
  assert distro.distro_from_dict(a) == Some(distro.Ascap)
}

pub fn mci_test() {
  let a = ["a", "b", "c", "a"]
  assert Ok("a") == fuzz.most_common_entry(a)

  let a = ["a", "b", "b", "c"]
  assert Ok("b") == fuzz.most_common_entry(a)
}

pub fn name_test() {
  let a = "Sunroof"
  let b = "sunroof (extended version)"
  assert fuzz.strings_are_equivalent(a, b)

  let a = "sunroof"
  let b = "sunroof (loud luxury remix)"
  assert fuzz.strings_are_equivalent(a, b)

  let a = "body bag"
  let b = "bodybag"
  assert fuzz.strings_are_equivalent(a, b)

  // TODO: make this test pass
  let a = "sexy villain"
  let b = "sexy villian"
  assert fuzz.strings_are_equivalent(a, b)

  // TODO: make this test pass
  let a = "fckboys"
  let b = "fuckboys"
  assert fuzz.strings_are_equivalent(a, b)

  // TODO: make this test pass (MAYBE)
  let a = "sunroof (arod remix)"
  let b = "sunroof (loud luxury remix)"
  assert fuzz.strings_are_equivalent(a, b)

  let a = "  "
  let b = "hello there"
  assert !fuzz.strings_are_equivalent(a, b)

  let a = "bird's eye view"
  let b = "bird s eye view"
  assert fuzz.strings_are_equivalent(a, b)

  let a = "sunroof"
  let b = "froofsun"
  assert !fuzz.strings_are_equivalent(a, b)
}
