-- Step 1: Insert unique artists (lowercased to handle case inconsistencies)
INSERT INTO artists (name)
SELECT DISTINCT LOWER(artist)
FROM raw_charts
WHERE artist IS NOT NULL;

-- Step 2: Insert unique tracks (using DISTINCT ON url to avoid duplicates)
INSERT INTO tracks (title, artist_id, url)
SELECT DISTINCT ON (rc.url) rc.title, a.artist_id, rc.url
FROM raw_charts rc
JOIN artists a ON a.name = LOWER(rc.artist)
ORDER BY rc.url;

-- Step 3: Insert chart entries
INSERT INTO charts (track_id, region, chart_date, position, streams, chart, trend)
SELECT t.track_id, rc.region, rc.date, rc.rank, rc.streams, rc.chart, rc.trend
FROM raw_charts rc
JOIN tracks t ON t.url = rc.url;
