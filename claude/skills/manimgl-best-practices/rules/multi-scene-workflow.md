---
name: multi-scene-workflow
description: Multi-scene video project workflow with render/concat/main script separation
metadata:
  tags: workflow, multi-scene, render, concat, ffmpeg, project-structure, batch
---

# マルチシーン動画プロジェクトのスクリプト分離パターン

## 原則

ManimGLで複数シーンの動画を作る場合、**レンダリング**と**結合**を別スクリプトに分離する。

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

QUALITY="${1:-l}"  # l=low, m=medium, h=high

# ManimGL品質フラグのマッピング
case "${QUALITY}" in
  l) Q_FLAG="-l" ;;
  m) Q_FLAG="-m" ;;
  h) Q_FLAG="-h" ;;
  *) echo "Usage: $0 [l|m|h]"; exit 1 ;;
esac

SCENES=(
  "video/scenes/scene_01_hook.py Scene1Hook"
  "video/scenes/scene_02_pipeline.py Scene2Pipeline"
  # ... 追加シーン
)

echo "=== Rendering ${#SCENES[@]} scenes at quality: ${Q_FLAG} ==="

for entry in "${SCENES[@]}"; do
  file="${entry% *}"
  class="${entry#* }"
  echo "--- ${class} ---"
  manimgl "${file}" "${class}" ${Q_FLAG} -w
done

echo "=== Done. Output: media/videos/ ==="
```

### ManimCEとの違い

- ManimGLは `-l` / `-m` / `-h` で品質指定（ManimCEの `-ql` / `-qm` / `-qh` とは異なる）
- ManimGLはデフォルトでプレビューウィンドウを開くので、バッチレンダリングには **`-w` フラグ**（ファイルに書き出し）が必須
- `SCENES` 配列のフォーマットはManimCEと同一

## concat.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

QUALITY="${1:-l}"

# ManimGLのデフォルト出力ディレクトリ
# custom_config.yml の directories.output に依存する（デフォルト: ./media/videos）
VIDEO_DIR="media/videos"

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
  # ManimGLの出力: {output_dir}/{シーンファイル名(拡張子なし)}/{クラス名}.mp4
  mp4="$(pwd)/${VIDEO_DIR}/${dir}/${class}.mp4"
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

OUTPUT="${VIDEO_DIR}/project_full_${QUALITY}.mp4"
ffmpeg -f concat -safe 0 -i "${CONCAT_LIST}" -c copy -y "${OUTPUT}" 2>/dev/null
rm -f "${CONCAT_LIST}"

echo "=== Combined ${FOUND} scenes → ${OUTPUT} ==="
```

### ManimCEとの違い

- ManimGLは品質別のサブディレクトリ（`480p15/` 等）を作らない。出力先は `{output_dir}/{ファイル名}/{クラス名}.mp4`
- そのため concat.sh のパス解決がシンプルになる
- 品質を変えてレンダリングすると同じパスに上書きされるので注意
- 品質別に保持したい場合は `custom_config.yml` の `directories.output` を変えるか、レンダリング後にファイルを移動する

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
| 特定シーンだけ再レンダリング後に結合 | 手動で `manimgl ... -h -w` → `./video/concat.sh h` |

## 注意: ManimGLの出力ディレクトリ

ManimGLの出力先は `custom_config.yml` で設定する:

```yaml
directories:
  output: "./media/videos"
```

ManimCEと異なり品質別サブディレクトリは作られないため、異なる品質で同じシーンをレンダリングすると上書きされる。品質別に保持したい場合は出力ディレクトリを分ける:

```bash
# 品質別にディレクトリを分ける例
manimgl scene.py MyScene -h -w --config directories.output=./media/videos/high
manimgl scene.py MyScene -l -w --config directories.output=./media/videos/low
```
