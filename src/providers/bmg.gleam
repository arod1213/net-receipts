import models/header.{Header}
import providers/globals.{global_isrcs, global_iswcs, global_upcs}

pub fn headers() {
  Header(
    id: ["Statement ID Number"],
    earnings: ["Royalty Payable"],
    titles: ["Song Title"],
    artists: ["Artist"],
    dates: ["Income Period"],
    isrcs: global_isrcs,
    iswcs: global_iswcs,
    upcs: global_upcs,
    territory: ["Royalty Country Code"],
  )
}
// Income
// Period
// Numerical Specifies the period (range)
// the income was collected in.
// Format: yyyymmyyyymm
// (year/month from -
// year/month to).
// 201510201512
// (= 2015-Oct - 2015-Dec) 
