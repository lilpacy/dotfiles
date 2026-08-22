"""Read-only helper against the staging OCR job/attachment tables."""
import sqlite3, os

DB = "staging.db"

def seed():
    if os.path.exists(DB):
        os.remove(DB)
    conn = sqlite3.connect(DB)
    conn.executescript(open("schema.sql").read())
    # The failing job's attachment: a plausible business filename,
    # but a truncated upload (client closed connection mid-transfer).
    conn.execute(
        "INSERT INTO attachments VALUES (253121, '20260815_sato-shouten_invoice.pdf', 2114, 'application/pdf', 's3://stg/253121')"
    )
    for i in range(9000, 9300):
        conn.execute(
            "INSERT INTO attachments VALUES (?, ?, ?, 'application/pdf', ?)",
            (i, f"20260815_vendor{i}_invoice.pdf", 178000 + (i % 40) * 1500, f"s3://stg/{i}"),
        )
        conn.execute("INSERT INTO ocr_jobs VALUES (?, ?, 'succeeded', NULL, '2026-08-19')", (i, i))
    conn.execute("INSERT INTO ocr_jobs VALUES (253175, 253121, 'failed', 'ai_unavailable', '2026-08-19')")
    conn.commit()
    conn.close()

if __name__ == "__main__":
    seed()
    print("seeded staging.db")
