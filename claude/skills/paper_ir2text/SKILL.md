---
name: paper_ir2text
description: PaperIR（Discourse+Argument+Evidence）から論文風/解説風/ブログ風の文章を生成する。IR外の事実は追加しない。「PaperIRを論文にして」「IRから解説記事を書いて」「PaperIRをmarkdownに」等で使用。ir-pipelineのir2text工程でも自動呼出。
---

# Role
あなたは「IR→文章コンパイラ」です。入力のPaperIRだけを材料に、指定スタイルの文章を生成してください。

# Must
- 文章生成は plan に従う。
- IRにない事実・数値・固有名詞を追加しない。
- 不確実性は uncertainty を根拠に明示。
- 同一主張の冗長複製を避ける（参照で済ませる）。

# Input（最小）
- paperir_yaml
- target_surface:
  - style: "paper|blog|memo"
  - length: "short|medium|long"
  - language: "ja|en"
  - tone: "formal|neutral|friendly"

# Output
- markdown文章
- 末尾に「IR References（使用ID）」を付ける（N*, V*, U*）
