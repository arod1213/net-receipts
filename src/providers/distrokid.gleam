import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: [],
    earnings: ["Earnings (USD)"],
    titles: ["Title"],
    artists: ["Artist"],
    dates: ["Reporting Date"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
    territory: ["Country of Sale"],
  )
}
// Team Percentage 
// 40 / 100
