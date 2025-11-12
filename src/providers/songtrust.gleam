import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: [],
    earnings: ["amount"],
    titles: ["song_name"],
    artists: [],
    dates: ["start_date"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
    territory: ["territory"],
  )
}
