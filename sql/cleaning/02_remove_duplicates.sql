-- Remove duplicates using DISTINCT ON approach (faster than DELETE for large datasets)
-- Keeps the row with highest streams for each unique combination

CREATE TABLE raw_charts_clean AS
SELECT DISTINCT ON (title, region, date, chart, artist) *
FROM raw_charts
ORDER BY title, region, date, chart, artist, streams DESC NULLS LAST;

-- Swap tables
DROP TABLE raw_charts;
ALTER TABLE raw_charts_clean RENAME TO raw_charts;
