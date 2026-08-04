#!/usr/bin/env python3
"""Review stage-gate readiness for a design-case JSON."""
from __future__ import annotations
import argparse, json
from pathlib import Path
from typing import Any

STAGES = [
 ("business_workflow","Business Workflow"),
 ("decision_flow","Decision Flow"),
 ("decision_table","Decision Table"),
 ("design_principles","Design Principles"),
 ("contradiction_check","Contradiction Check"),
 ("state_machine","State Machine"),
 ("information_architecture","Information Architecture"),
 ("ui_behavior","UI Behavior"),
]

def load(path: Path) -> dict[str,Any]:
    return json.loads(path.read_text(encoding="utf-8"))

def nonempty(value: Any) -> bool:
    return bool(str(value).strip())

def checks(data: dict[str,Any]) -> dict[str,list[str]]:
    p=data.get("project",{})
    stages: dict[str,list[str]]={}
    stages["business_workflow"] = []
    if not nonempty(p.get("scope","")): stages["business_workflow"].append("project.scopeが未定義")
    if not p.get("success_conditions"): stages["business_workflow"].append("成功条件がない")
    if not data.get("actors"): stages["business_workflow"].append("アクターがない")
    if len(data.get("business_workflow",{}).get("steps",[]))<2: stages["business_workflow"].append("業務ステップが2件未満")

    stages["decision_flow"]=[]
    if not data.get("decisions"): stages["decision_flow"].append("意思決定点がない")
    for d in data.get("decisions",[]):
        if not nonempty(d.get("question","")): stages["decision_flow"].append(f"{d.get('id')} questionなし")
        if not nonempty(d.get("applies_when","")): stages["decision_flow"].append(f"{d.get('id')} 発生条件なし")
        if not d.get("options"): stages["decision_flow"].append(f"{d.get('id')} 選択肢なし")

    stages["decision_table"]=[]
    dt=data.get("decision_table",{})
    for key in ("conditions","actions","cases"):
        if not dt.get(key): stages["decision_table"].append(f"{key}がない")

    stages["design_principles"]=[]
    principles=data.get("principles",[])
    if len(principles)<2: stages["design_principles"].append("原則が2件未満")
    priorities=[p.get("priority") for p in principles]
    if len(priorities)!=len(set(priorities)): stages["design_principles"].append("原則の優先順位が重複")
    for p0 in principles:
        if not nonempty(p0.get("verification","")): stages["design_principles"].append(f"{p0.get('id')} 検証方法なし")

    stages["contradiction_check"]=[]
    for c in data.get("contradictions",[]):
        if c.get("severity")=="blocking" and c.get("status")=="open":
            stages["contradiction_check"].append(f"Open Blocking {c.get('id')}: {c.get('reason','')}")

    stages["state_machine"]=[]
    sm=data.get("state_machine",{})
    states=sm.get("states",[]); transitions=sm.get("transitions",[])
    state_ids={s.get("id") for s in states}
    if sm.get("initial_state_id") not in state_ids: stages["state_machine"].append("初期状態がない")
    if len(states)<2: stages["state_machine"].append("状態が2件未満")
    if not transitions: stages["state_machine"].append("遷移がない")
    tags={tag for d in data.get("decisions",[]) for tag in (d.get("tags") or [])}
    types={s.get("type") for s in states}
    if "long_running_action" in tags and "processing" not in types:
        stages["state_machine"].append("長時間処理にprocessing状態がない")
    if "long_running_action" in tags and "failure" not in types:
        stages["state_machine"].append("長時間処理にfailure状態がない")

    stages["information_architecture"]=[]
    nodes=data.get("information_architecture",{}).get("nodes",[])
    if not nodes: stages["information_architecture"].append("IAノードがない")
    for n in nodes:
        if not n.get("state_ids") and not n.get("decision_ids"):
            stages["information_architecture"].append(f"{n.get('id')} に状態・決定の参照がない")

    stages["ui_behavior"]=[]
    uis=data.get("ui_behaviors",[])
    if not uis: stages["ui_behavior"].append("UI挙動がない")
    for u in uis:
        required=["display_condition","user_action","system_result","feedback","recovery"]
        missing=[k for k in required if not nonempty(u.get(k,""))]
        if missing: stages["ui_behavior"].append(f"{u.get('id')} 未定義: {', '.join(missing)}")
        if not u.get("decision_ids") or not u.get("state_ids"):
            stages["ui_behavior"].append(f"{u.get('id')} トレーサビリティ不足")
    return stages

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--json",action="store_true")
    args=ap.parse_args()
    data=load(Path(args.path))
    blockers=checks(data)
    prior_ready=True
    rows=[]
    for sid,label in STAGES:
        own=blockers[sid]
        if not prior_ready:
            status="blocked_by_upstream"
        elif own:
            status="blocked"
            prior_ready=False
        else:
            status="ready"
        rows.append({"id":sid,"label":label,"status":status,"blockers":own})
    next_stage=next((r["id"] for r in rows if r["status"] in {"blocked","blocked_by_upstream"}),None)
    if args.json:
        print(json.dumps({"stages":rows,"next_stage":next_stage},ensure_ascii=False,indent=2))
    else:
        print("| Stage | Status | Blockers |")
        print("|---|---|---|")
        for r in rows:
            print(f"| {r['label']} | {r['status']} | {'; '.join(r['blockers']) or '-'} |")
        print(f"\nNext stage: {next_stage or 'complete'}")
    return 1 if any(r["status"]=="blocked" for r in rows) else 0

if __name__=="__main__":
    raise SystemExit(main())
