---
name: multi-scene-workflow
description: Multi-scene video project workflow with render/concat/main script separation
metadata:
  tags: workflow, multi-scene, render, concat, ffmpeg, project-structure, batch
---

# マルチシーン動画プロジェクトのスクリプト分離パターン

## 原則

Manimで複数シーンの動画を作る場合、**レンダリング**と**結合**を別スクリプトに分離する。

- `render.sh` — 各シーンを個別にレンダリング
- `concat.sh` — レンダリング済みMP4をffmpegで無劣化結合
- `main.sh` — 上記2つを順に実行

## なぜ分けるのか

- シーン1つだけ修正した場合、`render.sh`で全シーン再レンダリング → `concat.sh`で結合、という流れになるが、**結合だけやり直したい**ケースが頻繁にある（既にレンダリング済みのシーンを並べ替える、特定シーンだけ差し替えた後に結合し直す等）
- レンダリングは重い処理（分〜十分単位）、結合は軽い処理（秒単位）。分離することで不要な再レンダリングを避けられる
- CIやプレビューで品質を切り替える際、結合ロジックは品質に依存しない（ディレクトリ名だけ変わる）

## ファイル構成

```
video/
├── render.sh    # レンダリング
├── concat.sh    # 結合
├── main.sh      # レンダリング + 結合
└── scenes/
    ├── scene_01_*.py
    ├── scene_02_*.py
    └── ...
```

## render.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

export PYTHONPATH="/tmp/claude/manim_pkg:${PYTHONPATH:-}"

QUALITY="${1:-l}"  # l=low(480p), m=medium(720p), h=high(1080p)

SCENES=(
  "video/scenes/scene_01_hook.py Scene1Hook"
  "video/scenes/scene_02_pipeline.py Scene2Pipeline"
  # ... 追加シーン
)

echo "=== Rendering ${#SCENES[@]} scenes at quality: -q${QUALITY} ==="

for entry in "${SCENES[@]}"; do
  file="${entry% *}"
  class="${entry#* }"
  echo "--- ${class} ---"
  python3 -m manim -q"${QUALITY}" "${file}" "${class}"
done

echo "=== Done. Output: media/videos/ ==="
```

### ポイント

- `SCENES` 配列に `"ファイルパス クラス名"` のペアを持たせる
- `${entry% *}` でファイルパス、`${entry#* }` でクラス名を分離
- 品質は `l`/`m`/`h` の1文字で指定。ManimCEの `-q` フラグにそのまま渡せる

## concat.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

QUALITY="${1:-l}"

case "${QUALITY}" in
  l) RESOLUTION_DIR="480p15" ;;
  m) RESOLUTION_DIR="720p30" ;;
  h) RESOLUTION_DIR="1080p60" ;;
  *) echo "Usage: $0 [l|m|h]"; exit 1 ;;
esac

SCENES=(
  "scene_01_hook Scene1Hook"
  "scene_02_pipeline Scene2Pipeline"
  # ... 追加シーン
)

CONCAT_LIST="$(mktemp)"
FOUND=0
for entry in "${SCENES[@]}"; do
  dir="${entry% *}"
  class="${entry#* }"
  mp4="$(pwd)/media/videos/${dir}/${RESOLUTION_DIR}/${class}.mp4"
  if [ -f "${mp4}" ]; then
    echo "file '${mp4}'" >> "${CONCAT_LIST}"
    FOUND=$((FOUND + 1))
  else
    echo "Warning: not found: ${mp4}"
  fi
done

if [ "${FOUND}" -eq 0 ]; then
  echo "Error: no rendered scenes found. Run ./video/render.sh ${QUALITY} first"
  rm -f "${CONCAT_LIST}"
  exit 1
fi

OUTPUT="media/project_full_${RESOLUTION_DIR}.mp4"
ffmpeg -f concat -safe 0 -i "${CONCAT_LIST}" -c copy -y "${OUTPUT}" 2>/dev/null
rm -f "${CONCAT_LIST}"

echo "=== Combined ${FOUND} scenes → ${OUTPUT} ==="
```

### ポイント

- `ffmpeg -f concat -safe 0 -c copy` で**無劣化結合**。再エンコードしないので数秒で完了する
- ManimCEの出力はすべて同一コーデック・解像度・フレームレートなので concat demuxer が使える
- 存在しないファイルはスキップしてWarningを出す（部分的な結合も可能）
- 出力ファイル名に解像度を含める

## main.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

QUALITY="${1:-l}"

"$(dirname "$0")/render.sh" "${QUALITY}"
"$(dirname "$0")/concat.sh" "${QUALITY}"
```

## 使い分け

| やりたいこと | コマンド |
|---|---|
| 全シーンレンダリング + 結合 | `./video/main.sh h` |
| レンダリングだけ | `./video/render.sh h` |
| 結合だけ（レンダリング済み前提） | `./video/concat.sh h` |
| 特定シーンだけ再レンダリング後に結合 | 手動で `manim -qh ...` → `./video/concat.sh h` |

## ManimCEの品質と出力ディレクトリの対応

| フラグ | 解像度 | ManimCE出力ディレクトリ |
|---|---|---|
| `-ql` | 480p 15fps | `media/videos/シーン名/480p15/` |
| `-qm` | 720p 30fps | `media/videos/シーン名/720p30/` |
| `-qh` | 1080p 60fps | `media/videos/シーン名/1080p60/` |

この対応を `concat.sh` の `case` 文でハードコードしている。ManimCEのバージョンアップでディレクトリ命名規則が変わった場合は要更新。
