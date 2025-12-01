# Net Receipts API

**A royalty statement aggregator and analyzer for independent musicians.**

Gleamer parses CSV/TSV royalty statements from multiple distributors and music rights organizations, automatically consolidating duplicate entries, matching metadata, and providing insights into your catalog's performance.

## Features

### Multi-Distributor Support

Automatically detects and parses statements from:

- **ASCAP & BMI** - Performance royalties
- **Songtrust** - Publishing administration
- **MLC (Mechanical Licensing Collective)** - Mechanical royalties
- **Vydia** - Digital distribution
- **SoundExchange** - Digital performance royalties

### Smart Data Aggregation

- **Fuzzy matching** of song titles and artist names across different formats
- **Metadata consolidation** - Aggregates UPC, ISRC, and ISWC codes from multiple sources
- **Duplicate detection** - Automatically merges entries for the same song with slight variations

### Analytics & Insights

- **Per-song earnings** - Total revenue and breakdown by distributor
- **Catalog overview** - Total earnings across all songs
- **Historical tracking** - Compare earnings over time by uploading multiple periods
- **Distributor comparison** - See which platforms generate the most revenue

## Quick Start

### Upload Statements & Get Song-Level Breakdown

```bash
curl -X POST "http://localhost:8080/read/song" \
  -F files=@ascap_q1_2024.csv \
  -F files=@spotify_january_2024.csv \
  -F files=@soundexchange_2024.tsv
```

### Search Specific Song

```bash
curl -X POST "http://localhost:8080/read/song/peaches" \
  -F files=@my_royalty_statement.csv
```

Returns only songs matching "peaches" (fuzzy search included).

### Get Raw Payment Data

```bash
curl -X POST "http://localhost:8080/read/payment" \
  -F files=@my_royalty_statement.csv
```

Returns individual payment records without aggregation.

## How It Works

1. **Upload** - Send CSV/TSV files from any supported distributor
2. **Parse** - Gleamer detects the format and extracts payment data
3. **Match** - Songs are matched across statements using fuzzy title/artist matching
4. **Aggregate** - Metadata (ISRC, UPC, ISWC) is consolidated from all sources
5. **Analyze** - Earnings are summed per song and broken down by distributor

## Supported File Formats

- **CSV** (comma-separated)
- **TSV** (tab-separated)
- Auto-detects delimiter

## Development

```sh
gleam run   # Run the server (default: localhost:8080)
gleam test  # Run the test suite
```

---

**Built with [Gleam](https://gleam.run/)** - A friendly language for building type-safe systems that scale.
