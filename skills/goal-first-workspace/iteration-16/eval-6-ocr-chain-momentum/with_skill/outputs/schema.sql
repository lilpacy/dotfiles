CREATE TABLE ocr_jobs (
  id INTEGER PRIMARY KEY,
  attachment_id INTEGER,
  status TEXT,
  last_error TEXT,
  created_at TEXT
);

CREATE TABLE attachments (
  id INTEGER PRIMARY KEY,
  filename TEXT,
  size_bytes INTEGER,
  content_type TEXT,
  s3_key TEXT
);
