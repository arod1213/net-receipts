import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["ID"],
    earnings: ["Net"],
    titles: ["Title"],
    artists: ["Artists"],
    dates: ["Accounted Date"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
  )
}
