-- Trim whitespace from text fields
UPDATE raw_charts SET title = TRIM(title);
UPDATE raw_charts SET artist = TRIM(artist);
UPDATE raw_charts SET region = TRIM(region);
