import models/header.{Header}

pub fn headers() {
  Header(
    id: global_ids,
    titles: global_titles,
    earnings: global_earnings,
    artists: global_artists,
    dates: global_dates,
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
    territory: global_territory,
  )
}

pub const global_territory = ["Territory"]

pub const global_isrcs = ["ISRC", "isrc"]

pub const global_upcs = ["UPC", "Album UPC", "Release UPC"]

pub const global_iswcs = ["ISWC", "iswc"]

const global_titles = [
  "Work Primary Title",
  "MusicalWorkTitle",
  "Work Title",
  "Track Name",
  "song_name",
  "Title",
]

const global_ids = [
  "Work Number",
  "Member IPI Name Number",
  "Royalty Item SXID",
  "UID",
  "Statement Recipient ID",
  "song_code",
]

const global_artists = [
  "Performing Artist",
  "Artist",
  "Recording Display Artist Name",
  "Artist Name",
]

const global_earnings = [
  "Royalty Amt",
  "Distributed Amount",
  "Your Payment Amount",
  "Earnings (USD)",
  "USD Amount",
  "$ Amount",
  "Dollars",
  "amount_received",
]

const global_dates = [
  "Transaction Date",
  "Distribution Date",
  "Broadcast Start Date",
  "start_date",
  "Usage Period Start Date",
  "Reporting Date",
]
