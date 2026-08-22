-- staging DB, simplified
CREATE TABLE ocr_jobs (
  id INTEGER PRIMARY KEY,
  attachment_id INTEGER,
  status TEXT,          -- 'succeeded' | 'failed'
  last_error TEXT,
  created_at TEXT
);

CREATE TABLE attachments (
  id INTEGER PRIMARY KEY,
  filename TEXT,
  size_bytes INTEGER,
  s3_key TEXT
);
