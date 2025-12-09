import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["TITLE #"],
    earnings: ["ROYALTY AMOUNT"],
    titles: ["TITLE NAME"],
    artists: [],
    dates: ["PERF PERIOD"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
    territory: ["COUNTRY OF PERFORMANCE"],
  )
}
