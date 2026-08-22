# incident memo

- staging で invoice OCR job `253175` が `ai_unavailable` で失敗し続けている
- Gemini呼び出しのエラーコードだけがログに出ており、何が原因かは分からない
- `attachments` テーブルに job の元ファイル情報がある（filename, size_bytes, s3_key）
- この1件以外の直近ジョブはすべて succeeded
- DBはstaging環境からread-onlyで参照可能（schema.sql, seed_and_query.py で再現できる）
