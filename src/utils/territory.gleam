import gleam/list
import gleam/string

pub fn standard_case(s) {
  s
  |> string.split(" ")
  |> list.map(fn(x) {
    x
    |> string.to_graphemes
    |> list.index_map(fn(a, i) {
      case i == 0 {
        True -> a |> string.uppercase
        False -> a
      }
    })
    |> string.join("")
  })
  |> string.join(" ")
}

pub fn territory_code_to_name(code: String) {
  case code {
    "US" -> "United States"
    "CA" -> "Canada"
    "GB" | "UK" -> "United Kingdom"
    "DE" -> "Germany"
    "FR" -> "France"
    "ES" -> "Spain"
    "IT" -> "Italy"
    "JP" -> "Japan"
    "CN" -> "China"
    "IN" -> "India"
    "BR" -> "Brazil"
    "RU" -> "Russia"
    "MX" -> "Mexico"
    "AU" -> "Australia"
    "NL" -> "Netherlands"
    "SE" -> "Sweden"
    "CH" -> "Switzerland"
    "AR" -> "Argentina"
    "BE" -> "Belgium"
    "PL" -> "Poland"
    "NO" -> "Norway"
    "DK" -> "Denmark"
    "FI" -> "Finland"
    "IE" -> "Ireland"
    "NZ" -> "New Zealand"
    "KR" | "KO" -> "South Korea"
    "ZA" -> "South Africa"
    "NG" -> "Nigeria"
    "EG" -> "Egypt"
    "TR" -> "Turkey"
    "SA" -> "Saudi Arabia"
    "IR" -> "Iran"
    "AE" -> "United Arab Emirates"
    "HK" -> "Hong Kong"
    "TW" -> "Taiwan"
    "SG" -> "Singapore"
    "MY" -> "Malaysia"
    "TH" -> "Thailand"
    "ID" -> "Indonesia"
    "PH" -> "Philippines"
    "VN" -> "Vietnam"
    "PK" -> "Pakistan"
    "BD" -> "Bangladesh"
    "LK" -> "Sri Lanka"
    "CZ" -> "Czech Republic"
    "GR" -> "Greece"
    "PT" -> "Portugal"
    "HU" -> "Hungary"
    "RO" -> "Romania"
    "BG" -> "Bulgaria"
    "AT" -> "Austria"
    s ->
      case s |> string.length > 2 {
        True -> s |> standard_case
        False -> s
      }
  }
}
