import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["Sender Transaction ID"],
    earnings: ["Distributed Amount"],
    titles: ["Recording Title"],
    artists: ["Recording Display Artist Name"],
    dates: ["Distribution Date"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
  )
}
