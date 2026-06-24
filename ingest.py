import psycopg2
import pandas as pd
import sys
DB_CONFIG = {
    "dbname": "spotify_charts",
    "user": "postgres",
    "password": "ADLAKHA",
    "host": "localhost",
    "port": 5432
}

def clean_dataframe(df):
    """Apply basic cleaning to raw dataframe"""
    df['artist'] = df['artist'].fillna('Unknown Artist').str.strip()
    df['title'] = df['title'].fillna('').str.strip()
    df['region'] = df['region'].str.upper().str.strip()
    df = df.dropna(subset=['title'])
    df = df.drop_duplicates(subset=['title', 'region', 'date', 'chart', 'artist'])
    return df

def load_to_raw(df, conn):
    """Load cleaned dataframe into raw_charts table"""
    cursor = conn.cursor()
    rows_inserted = 0
    for _, row in df.iterrows():
        try:
            cursor.execute("""
                INSERT INTO raw_charts (title, rank, date, artist, url, region, chart, trend, streams)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT DO NOTHING
            """, (row['title'], row['rank'], row['date'], row['artist'],
                  row['url'], row['region'], row['chart'], row['trend'], row['streams']))
            rows_inserted += 1
        except Exception as e:
            print(f"Error on row: {e}")
    conn.commit()
    return rows_inserted

def main(filepath):
    print(f"Loading file: {filepath}")
    df = pd.read_csv(filepath)
    print(f"Raw rows: {len(df)}")
    
    df = clean_dataframe(df)
    print(f"Rows after cleaning: {len(df)}")
    
    conn = psycopg2.connect(**DB_CONFIG)
    inserted = load_to_raw(df, conn)
    conn.close()
    
    print(f"Successfully inserted {inserted} rows into raw_charts.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ingest.py path/to/charts.csv")
    else:
        main(sys.argv[1])
