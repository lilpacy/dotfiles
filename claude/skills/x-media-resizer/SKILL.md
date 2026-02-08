---
name: x-media-resizer
description: >
  画像・動画ファイルを X（旧Twitter）投稿向けに自動リサイズ/圧縮/変換する。
  具体的には、画像は自動回転（EXIF）→サイズ調整→5MB目標の圧縮、
  動画は変換（H.264/AACのMP4）→推奨解像度へリサイズ→（必要なら）140秒へトリム→faststart最適化を行い、
  dist/x に出力する。ユーザーが「添付の画像/動画をXに投稿できるサイズにして」「tweet用に圧縮して」などと言ったら起動。
allowed-tools:
  - bash
---

# X Media Resizer

X（旧Twitter）に投稿しやすい形に、画像/動画を自動で整形して `dist/x/` に出力します（元ファイルは変更しません）。

## Prerequisites

- macOS: `brew install ffmpeg imagemagick`
- Linux: `ffmpeg` と `imagemagick` をインストール

## Quick Start

- 指定ファイルを変換
  - `bash scripts/x_media_resize.sh path/to/media1.jpg path/to/movie.mov`
- 何も指定しない場合
  - `./attachments` → なければカレント配下から、画像/動画っぽい拡張子を探索して変換します

## What it does

### Images
- EXIFに従って自動回転（-auto-orient）
- `--preset auto` の場合、元画像の向きで以下を自動選択して出力
  - landscape: 1200x675（16:9）
  - portrait: 1080x1350（4:5）
  - square: 1200x1200（1:1）
- 画像サイズが大きくなりすぎる場合はJPEG品質を落として **5MB以下を目標** に収めます（透過がある場合はPNG維持）

※ 画像のサイズ上限や推奨はUIや用途で揺れますが、1:1 / 16:9 / 1.91:1 などが一般的に使われます。参考: resources/x_media_specs.md

### Videos / GIF
- MP4（H.264 / AAC）に統一して出力
- `--preset auto` の場合、元動画の向きで以下を自動選択して出力
  - landscape: 1280x720
  - portrait: 720x1280
  - square: 720x720
- アスペクト比は維持し、余白は pad（レターボックス）で埋めます（`--strategy crop`で中央クロップにも変更可）
- デフォルトで **140秒を超える場合は140秒まで** にトリムします（`--no-trim`で無効化）
- `-movflags +faststart`（アップロード/再生開始を早める）を付与

## Output

- 出力先: `dist/x/`
- ファイル名: `<元名>__x_<preset>.<ext>`

## Options (script)

- `--preset auto|landscape|portrait|square|wide-card`
- `--strategy pad|crop|fit`
- `--out-dir dist/x`
- `--max-image-mb 5`
- `--max-video-sec 140`
- `--no-trim`
- `--dry-run`

## Examples (activation)

- 「このフォルダの画像と動画を X に投稿できるサイズにして」
- 「添付の MOV を mp4 にして、140秒以内に収めて」
- 「正方形サムネとして 1200x1200 で出して」
- 「リンクカードっぽい横長（1.91:1）に揃えて」

## Reference

- `resources/x_media_specs.md`
- `scripts/x_media_resize.sh --help`
