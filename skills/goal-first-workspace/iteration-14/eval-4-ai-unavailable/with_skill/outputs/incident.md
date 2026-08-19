# incident memo

- staging の /api/generate が今朝から高頻度で `ai_unavailable` を返す
- staging のログには `generate failed: ai_unavailable` が並ぶだけで、
  それ以上の情報が何も出ていない
- ローカルでは再現しない（ローカルから provider へは疎通する）
- staging への反映は CI 経由。ビルド〜反映で約30分、レビュー待ちを
  含めると1往復1〜2時間かかる
- provider の手前に社内 proxy がある構成
