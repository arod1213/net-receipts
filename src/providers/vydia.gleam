import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["UID"],
    earnings: ["USD Amount"],
    titles: ["Title"],
    artists: ["Artist"],
    dates: ["Transaction Date"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
  )
}
