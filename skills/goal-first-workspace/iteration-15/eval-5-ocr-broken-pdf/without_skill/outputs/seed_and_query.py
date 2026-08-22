"""Read-only helper against the staging OCR job/attachment tables.
Run with sqlite3 for local reproduction of the staging incident."""
import sqlite3

DB = "staging.db"

def seed():
    conn = sqlite3.connect(DB)
    conn.executescript(open("schema.sql").read())
    conn.execute("INSERT INTO attachments VALUES (253121, 'broken_破損.pdf', 2000, 's3://stg/253121')")
    for i in range(9000, 9300):
        conn.execute("INSERT INTO attachments VALUES (?, ?, ?, ?)",
                      (i, f"invoice_{i}.pdf", 180000 + i, f"s3://stg/{i}"))
        conn.execute("INSERT INTO ocr_jobs VALUES (?, ?, 'succeeded', NULL, '2026-08-19')", (i, i))
    conn.execute("INSERT INTO ocr_jobs VALUES (253175, 253121, 'failed', 'ai_unavailable', '2026-08-19')")
    conn.commit()
    conn.close()

if __name__ == "__main__":
    seed()
    print("seeded staging.db")
