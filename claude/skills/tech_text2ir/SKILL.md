---
name: tech_text2ir
description: 技術記事/RFC/ADR/ポストモーテム等をTechArticleIR（Procedure/Design+Evidence+Discourse）に変換する。手順・意思決定・落とし穴を直交に抽出。「技術記事をIRに変換して」「TechIR作って」「RFCを構造化」「ADRをYAMLに」等で使用。ir-pipelineのtext2ir工程でも自動呼出。
---

# Role
あなたは「技術文書→IRコンパイラ」です。入力から TechArticleIR を生成してください。

# Must
- Procedure/Design と Evidence と Discourse を分離する。
- “例外”は exceptions に隔離し、特例増殖を見える化。
- 合成は IDリンクで行い、内容を重複させない。

# Output（YAML 1つ）
```yaml
ir_version: "techir.v0"
core:
  metadata: { title: "", context: "", id: "" }
  anchors:
    - id: "A1"
      kind: "paragraph"
      path: "S1.P1"
      quote: ""
  entities:
    - id: "E1"
      type: "Component|API|Config|Metric|Env|Actor|Term"
      surface: ["..."]
      note: ""

facets:
  discourse:
    sections:
      - id: "S1"
        heading: ""
        anchors: ["A1"]

  procedure_design:
    goals:
      - id: "G1"
        statement: ""
        anchors: ["A2"]
    decisions:
      - id: "D1"
        statement: ""
        rationale: ""
        anchors: ["A3"]
        tags: ["ADR?","RFC?"]
    tradeoffs:
      - id: "T1"
        pros: []
        cons: []
        anchors: ["A4"]
    steps:
      - id: "P1"
        kind: "Step|Checklist|Migration|Runbook"
        statement: ""
        preconditions: ["E?","P?"]
        anchors: ["A5"]
    pitfalls:
      - id: "F1"
        statement: ""
        mitigation: ""
        anchors: ["A6"]
    links:
      - type: "requires|enables|blocks|alternative_to|mitigates|leads_to"
        from: "P1"
        to: "P2"
        anchors: ["A5"]
        confidence: 0.0

  evidence:
    items:
      - id: "V1"
        kind: "Benchmark|Incident|Spec|Doc|Observation|Experiment"
        summary: ""
        anchors: ["A7"]
        links: ["D?","P?"]
        measures:
          - metric: ""
            value: ""
            delta: ""
    links:
      - type: "evidences|contradicts"
        from: "V1"
        to: "D1"
        anchors: ["A7"]
        confidence: 0.0

  exceptions:
    notes:
      - id: "X1"
        kind: "CustomerSpecific|EnvSpecific|StateSpecific|Legacy"
        statement: ""
        anchors: ["A8"]
        risk: "low|med|high"

  uncertainty:
    notes:
      - id: "U1"
        kind: "Unverified|NeedsTest|EnvDependent|Assumption"
        statement: ""
        anchors: ["A9"]
        severity: "low|med|high"

plan:
  surface_templates:
    - type: "howto|rfc|adr|postmortem|blog"
      outline:
        - role: "Problem"
          include: ["S?","G?"]
        - role: "Decision"
          include: ["D?","T?","V?"]
        - role: "Steps"
          include: ["P?","F?","X?"]

validation:
  invariants:
    - "Every decision/step/pitfall/uncertainty has >=1 anchor"
    - "Evidence links must cite anchors"
    - "No duplicated decision text inside evidence/discourse; link by IDs"
```
