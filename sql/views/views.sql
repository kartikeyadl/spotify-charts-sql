-- View 1: Top artists by total streams
CREATE VIEW v_top_artists AS
SELECT a.name, SUM(c.streams) AS total_streams
FROM charts c
JOIN tracks t ON (c.track_id = t.track_id)
JOIN artists a ON (t.artist_id = a.artist_id)
GROUP BY a.name
ORDER BY total_streams DESC NULLS LAST;

-- View 2: Tracks that stayed in the Top 10 longest
CREATE VIEW v_chart_consistency AS
SELECT a.name, t.title, COUNT(*) AS days_in_top10
FROM charts c
JOIN tracks t ON (c.track_id = t.track_id)
JOIN artists a ON (t.artist_id = a.artist_id)
WHERE c.position <= 10
GROUP BY t.title, a.name
ORDER BY days_in_top10 DESC;

-- View 3: Top 5 tracks per region per year (using window functions)
CREATE VIEW v_top_tracks_per_region AS
WITH rnk AS (
    SELECT 
        t.title,
        a.name,
        c.region,
        EXTRACT(YEAR FROM c.chart_date) AS year,
        SUM(c.streams) AS total_streams,
        RANK() OVER (
            PARTITION BY c.region, EXTRACT(YEAR FROM c.chart_date)
            ORDER BY SUM(c.streams) DESC
        ) AS rnks
    FROM charts c
    JOIN tracks t ON (c.track_id = t.track_id)
    JOIN artists a ON (t.artist_id = a.artist_id)
    WHERE c.chart = 'top200'
    GROUP BY t.title, a.name, c.region, EXTRACT(YEAR FROM c.chart_date)
)
SELECT * FROM rnk WHERE rnks <= 5;
