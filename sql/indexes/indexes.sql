-- Indexes on commonly filtered/joined columns
CREATE INDEX idx_charts_date ON charts(chart_date);
CREATE INDEX idx_charts_region ON charts(region);
CREATE INDEX idx_charts_track_id ON charts(track_id);
CREATE INDEX idx_tracks_artist_id ON tracks(artist_id);

-- Performance comparison:
-- Query: SELECT * FROM charts WHERE chart_date = '2020-06-15' AND region = 'Germany'
-- Before indexes (Sequential Scan):  405 ms
-- After indexes (Bitmap Index Scan):  26 ms
-- Improvement: 15x faster
