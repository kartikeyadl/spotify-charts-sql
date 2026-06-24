# Spotify Charts — SQL Data Quality & Query Optimization

A PostgreSQL project demonstrating database design, data cleaning, and query optimization using a real-world Spotify Charts dataset with **26 million rows**.

## Overview

This project takes raw Spotify daily chart data (Top 200 and Viral 50 charts across 70+ countries, 2017–2021) and builds a complete data pipeline: loading messy CSV data, cleaning it, designing a normalized relational schema, creating analytical views, and optimizing query performance with indexes.

## Dataset

- **Source:** [Kaggle — Spotify Charts by dhruvildave](https://www.kaggle.com/datasets/dhruvildave/spotify-charts)
- **Size:** ~26 million rows
- **Columns:** title, rank, date, artist, url, region, chart, trend, streams
- **Coverage:** Daily Top 200 and Viral 50 charts for 70+ countries, January 2017 – 2021

## Data Quality Findings

The raw data had several issues that needed cleaning before use:

- **5.8 million NULL stream values** — Viral 50 charts track sharing rather than streams, so the `streams` column is NULL for all viral50 entries. Decision: preserve NULLs rather than replace with 0, to avoid incorrect aggregations (e.g. `AVG(streams)` would be dragged down by false zeros).
- **Duplicate entries** — Same track appearing multiple times for the same region, date, and chart type. Examples: "Sleigh Ride" appearing up to 6 times on a single chart due to multiple artist recordings.
- **Case inconsistencies in artist names** — The same artist stored differently across entries (e.g. "FlowZeta" vs "Flowzeta"). Resolved during normalization by lowercasing artist names.
- **Whitespace inconsistencies** — Leading/trailing spaces in title, artist, and region fields cleaned with TRIM.

## Schema Design

The raw flat table was normalized into three related tables to eliminate redundancy:

```
artists                tracks                    charts
-----------            ----------------          ------------------
artist_id (PK)    <--  artist_id (FK)            chart_id (PK)
name                   track_id (PK)        <--  track_id (FK)
                       title                     region
                       url                       chart_date
                                                 position
                                                 streams
                                                 chart
                                                 trend
```

**Why normalize?**
- Artist name "Ed Sheeran" is stored once instead of millions of times
- Fixing a typo requires updating a single row in `artists`, not millions of rows
- Foreign key constraints ensure data integrity — no orphaned references

**Final table sizes:**
- `artists`: 95,810 rows
- `tracks`: 217,661 rows
- `charts`: 26,171,237 rows

## Cleaning Approach

All scripts are in `/sql/cleaning/` and are designed to run in order:

| Script | Purpose |
|--------|---------|
| `01_normalize_formats.sql` | Trims whitespace from title, artist, and region fields |
| `02_remove_duplicates.sql` | Removes duplicate entries using `DISTINCT ON`, keeping the row with highest streams |

Note: The deduplication uses a create-and-swap strategy (`CREATE TABLE ... AS SELECT DISTINCT ON ...` then `DROP` and `RENAME`) rather than `DELETE`, which is significantly faster on large datasets — 3 minutes vs 45+ minutes on 26M rows.

## SQL Views

Three analytical views in `/sql/views/views.sql`:

**v_top_artists** — Artists ranked by total streams across all regions and dates. Uses a three-table JOIN aggregating streams per artist.

**v_chart_consistency** — Tracks ranked by how many days they appeared in the Top 10. Each row in `charts` represents one day on a chart, so counting rows where `position <= 10` gives total days in the Top 10.

**v_top_tracks_per_region** — Top 5 tracks per region per year by total streams. Uses `RANK() OVER (PARTITION BY region, year ORDER BY SUM(streams) DESC)` with a CTE to filter to the top 5. Excludes viral50 entries since they have no stream data.

## Query Optimization

Indexes were added on columns frequently used in WHERE, JOIN, and ORDER BY clauses:

```sql
CREATE INDEX idx_charts_date ON charts(chart_date);
CREATE INDEX idx_charts_region ON charts(region);
CREATE INDEX idx_charts_track_id ON charts(track_id);
CREATE INDEX idx_tracks_artist_id ON tracks(artist_id);
```

### EXPLAIN ANALYZE Results

**Query:** `SELECT * FROM charts WHERE chart_date = '2020-06-15' AND region = 'Germany'`

| Metric | Before Indexes | After Indexes |
|--------|---------------|---------------|
| Scan Type | Parallel Sequential Scan | Bitmap Index Scan |
| Execution Time | 405 ms | 26 ms |
| Rows Scanned | 8.7M per worker | ~15K + 448K (via index) |
| Improvement | — | **15x faster** |

**Key insight:** Indexes don't always help. A query fetching an entire year of data (~22% of the table) still uses a Sequential Scan because the optimizer determines that scanning the full table is faster than jumping around an index for millions of rows. Indexes are most effective when retrieving a small, specific subset of data.

## Automation

`ingest.py` automates the data ingestion pipeline. Instead of manually importing CSVs through a GUI and running cleaning queries by hand, a single command handles reading, cleaning, and inserting:

```bash
python3 ingest.py data/charts.csv
```

The script reads the CSV with pandas, applies cleaning (NULL handling, whitespace trimming, deduplication), connects to PostgreSQL via psycopg2, and inserts the data.

## Project Structure

```
spotify-charts-sql/
├── ingest.py
├── README.md
├── data/
│   └── charts.csv
└── sql/
    ├── schema/
    │   └── 01_create_tables.sql
    ├── cleaning/
    │   ├── 01_normalize_formats.sql
    │   └── 02_remove_duplicates.sql
    ├── migration/
    │   └── 01_populate_normalized_tables.sql
    ├── views/
    │   └── views.sql
    └── indexes/
        └── indexes.sql
```

## How to Run

1. Install PostgreSQL and create the database:
   ```sql
   CREATE DATABASE spotify_charts;
   ```

2. Run the schema creation script: `sql/schema/01_create_tables.sql`

3. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/dhruvildave/spotify-charts) and load it:
   ```bash
   psql -U postgres -d spotify_charts -c "\COPY raw_charts FROM 'data/charts.csv' DELIMITER ',' CSV HEADER;"
   ```

4. Run cleaning scripts in order from `sql/cleaning/`

5. Run migration script from `sql/migration/`

6. Create views from `sql/views/views.sql`

7. Create indexes from `sql/indexes/indexes.sql`

## Tools Used

- **PostgreSQL 18** — Database
- **DBeaver** — GUI for SQL development
- **Python 3** (pandas, psycopg2) — Data ingestion automation
- **Git/GitHub** — Version control

