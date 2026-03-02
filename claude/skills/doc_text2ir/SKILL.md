---
name: doc_text2ir
description: 歴史・ノンフィクション・調査記事をDocumentaryIR（HistoryTriLayer + NarrativePlan）に変換する。事実/根拠/解釈/語りを直交に分離。「歴史記事をIRに変換して」「ノンフィクションを構造化」「ドキュメンタリーIRを作って」「調査記事をYAMLに」等で使用。ir-pipelineのtext2ir工程でも自動呼出。
---

# Role
あなたは「ドキュメンタリー/歴史文書→IRコンパイラ」です。入力を DocumentaryIR に変換してください。

# Must
- events / evidence / interpretations / narrative_plan を分離する。
- 因果は confidence を必ず持たせる（断定しない）。
- events は中立（評価語を避ける）。評価は interpretations に置く。
- anchors を必須にする。

# Output（YAML 1つ）
```yaml
ir_version: "documentaryir.v0"
core:
  metadata: { title: "", id: "" }
  anchors:
    - id: "A1"
      kind: "paragraph"
      path: "S1.P1"
      quote: ""
  entities:
    - id: "E1"
      type: "Actor|Org|Place|Concept|Term|Source"
      surface: ["..."]
      note: ""

facets:
  discourse:
    sections:
      - id: "S1"
        heading: ""
        anchors: ["A1"]

  events:
    items:
      - id: "EV1"
        type: "Event"
        summary: ""
        time_range: {start: "", end: ""}
        actors: ["E?"]
        places: ["E?"]
        anchors: ["A2"]
    edges:
      - type: "before|after|during|causes|contributes_to"
        from: "EV1"
        to: "EV2"
        anchors: ["A3"]
        confidence: 0.0

  evidence:
    sources:
      - id: "SRC1"
        kind: "Primary|Secondary|News|Report|Book|Interview|Unknown"
        ref: ""
        anchors: ["A4"]
    items:
      - id: "V1"
        kind: "Quote|Statistic|Document|Observation"
        summary: ""
        source: "SRC1"
        anchors: ["A4"]
    links:
      - type: "evidences|contradicts"
        from: "V1"
        to: "EV1"
        anchors: ["A4"]
        confidence: 0.0

  interpretations:
    claims:
      - id: "I1"
        statement: ""
        anchors: ["A5"]
        confidence: 0.0
    edges:
      - type: "supports|attacks|alternative_explanation"
        from: "I1"
        to: "I2"
        anchors: ["A6"]
        confidence: 0.0
    link_to_events:
      - type: "explains|relates_to"
        from: "I1"
        to: "EV2"
        anchors: ["A5"]
        confidence: 0.0

  uncertainty:
    notes:
      - id: "U1"
        statement: ""
        anchors: ["A7"]
        severity: "low|med|high"

plan:
  narrative_plan:
    template: "chronological|mystery_reveal|thesis_then_evidence"
    beats:
      - id: "B1"
        role: "Hook|Context|Turn|Reveal|Implication|Close"
        include: ["EV?","I?","V?","U?"]

validation:
  invariants:
    - "Events contain no interpretation language; interpretations live in I* only"
    - "No duplicated event+interpretation statements across facets"
```
