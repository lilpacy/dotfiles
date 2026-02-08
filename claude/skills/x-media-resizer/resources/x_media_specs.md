# X Media Specs (Practical Baseline)

このSkillは「なるべく多くのアカウント/投稿環境で通る」ベースラインに寄せます。

## Baseline constraints (widely compatible)

### Images (photo)
- ファイルサイズ上限: 5MB（公式ヘルプの投稿ガイド）
- 形式: JPEG / PNG / GIF（BMP/TIFFは不可）

### Videos
- ファイルサイズ上限: 512MB（API/メディアアップロード系の制約として明記あり）
- 長さ: 0.5〜140秒（= 2分20秒）を上限にするのが無難
- コーデック: H.264 + AAC / コンテナ: MP4 を推奨

参考（公式・一次情報）:
- help.x.com 「Posting gifs and pictures」（画像サイズ上限や形式）
- developer.x.com / docs.x.com の media upload best practices / size restrictions（512MB, 140秒など）

## Practical recommended dimensions (defaults in this skill)

画像:
- landscape: 1200x675 (16:9)
- portrait: 1080x1350 (4:5)
- square: 1200x1200 (1:1)
- wide-card: 1200x628 (1.91:1)  ※広告/カード比率として一般的

動画:
- landscape: 1280x720
- portrait: 720x1280
- square: 720x720

注意:
- 実際の「最適」は UI/クライアント/タイムライン表示仕様で変わり得ます。
- このSkillは「見た目を崩しにくい + 失敗しにくい」方を優先し、
  余白 pad（レターボックス）をデフォルトにしています（--strategy crop で中央クロップ可能）。
