import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["Royalty Item SXID"],
    earnings: ["Your Payment Amount"],
    titles: ["Track Name"],
    artists: ["Artist Name"],
    dates: ["Broadcast Start Date"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
    territory: [],
  )
}
