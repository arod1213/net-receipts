import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["Statement Recipient ID"],
    earnings: ["Dollars", "$ Amount"],
    titles: ["Track Name", "Work Title"],
    artists: ["Artist"],
    dates: ["Distribution Date"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
  )
}
