-- Raw table for CSV import
CREATE TABLE raw_charts (
    title TEXT,
    rank INTEGER,
    date DATE,
    artist TEXT,
    url TEXT,
    region TEXT,
    chart TEXT,
    trend TEXT,
    streams BIGINT
);

-- Normalized schema
CREATE TABLE artists (
    artist_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE tracks (
    track_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    artist_id INTEGER REFERENCES artists(artist_id),
    url TEXT
);

CREATE TABLE charts (
    chart_id SERIAL PRIMARY KEY,
    track_id INTEGER REFERENCES tracks(track_id),
    region TEXT,
    chart_date DATE,
    position INTEGER,
    streams BIGINT,
    chart TEXT,
    trend TEXT
);
