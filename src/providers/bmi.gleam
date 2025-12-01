import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["Work Number"],
    earnings: ["Royalty Amt"],
    titles: ["Title"],
    artists: [],
    dates: [],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
    territory: [],
  )
}
