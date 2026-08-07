#!/usr/bin/env python3
"""Select the single highest-priority open question for a design case."""
from __future__ import annotations
import argparse, json
from pathlib import Path

STAGES = (
    ("business_understanding", "Business Understanding"),
    ("decision_requirements", "Decision Requirements"),
    ("target_value_loop", "Target Value Loop"),
    ("decision_specification", "Decision Specification"),
    ("design_principles", "Design Principles"),
    ("contradiction_check", "Contradiction Check"),
    ("state_machine", "State Machine"),
    ("information_architecture", "Information Architecture"),
    ("ui_behavior", "UI Behavior"),
)
STAGE_ORDER = {stage_id: index for index, (stage_id, _) in enumerate(STAGES, start=1)}
STAGE_LABELS = dict(STAGES)

DEFAULTS = {
 "business_understanding":"現行業務は何を契機に始まり、どの状態になれば完了ですか？",
 "decision_requirements":"現行業務で、誰かが判断しなければ先へ進めない箇所はどこですか？",
 "target_value_loop":"利用者が価値を得るまでに、必ず残すべき最短の流れは何ですか？",
 "decision_specification":"この判断は、いつ、誰が、何を根拠に行いますか？",
 "design_principles":"二つの方針が衝突した場合、最優先する価値は何ですか？",
 "contradiction_check":"衝突している二つの決定のうち、どちらを上位原則として優先しますか？",
 "state_machine":"処理が失敗した場合、ユーザーはどの状態へ戻るべきですか？",
 "information_architecture":"現在の状態で最優先で見える必要がある情報は何ですか？",
 "ui_behavior":"この操作を実行した直後、画面は何を表示し、失敗時にどう戻しますか？"
}


def stage_summary(stage_id: str) -> dict[str, str | int]:
    return {
        "id": stage_id,
        "label": STAGE_LABELS[stage_id],
        "position": STAGE_ORDER[stage_id],
    }


def build_navigation(current: str) -> dict[str, object]:
    if current not in STAGE_ORDER:
        current = "business_understanding"
    position = STAGE_ORDER[current]
    previous_id = STAGES[position - 2][0] if position > 1 else None
    return {
        "previous_stage": stage_summary(previous_id) if previous_id else None,
        "current_stage": stage_summary(current),
        "progress": {
            "current": position,
            "total": len(STAGES),
            "label": f"{position}/{len(STAGES)}",
        },
    }


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--json",action="store_true")
    args=ap.parse_args()
    data=json.loads(Path(args.path).read_text(encoding="utf-8"))
    current=data.get("pipeline",{}).get("current_stage","business_understanding")
    if current not in STAGE_ORDER:
        current="business_understanding"
    open_q=[q for q in data.get("questions",[]) if q.get("status")=="open"]
    # Blocking contradiction questions get an automatic boost.
    open_blocking={c.get("id") for c in data.get("contradictions",[]) if c.get("severity")=="blocking" and c.get("status")=="open"}
    scored=[]
    for q in open_q:
        score=int(q.get("priority",0))
        reason=str(q.get("reason",""))
        if any(cid and cid in reason for cid in open_blocking): score += 100
        if q.get("stage")==current: score += 20
        score -= abs(STAGE_ORDER.get(q.get("stage"),99)-STAGE_ORDER[current])*3
        scored.append((score,q))
    if scored:
        score,q=max(scored,key=lambda x:x[0])
        result={"navigation":build_navigation(current),"source":"queue","score":score,"question":q}
    else:
        result={"navigation":build_navigation(current),"source":"default","score":0,"question":{
            "id":None,"stage":current,"question":DEFAULTS.get(current,DEFAULTS["business_understanding"]),
            "priority":0,"reason":"現在ステージの既定質問","status":"suggested","answer":"",
            "answer_type":"free_text","recommended_answer":"",
            "recommendation_reason":"既知情報だけでは推奨案を一意に置けないため",
            "answer_guide":"判断に必要な事実を1〜2文で答えてください"
        }}
    if args.json:
        print(json.dumps(result,ensure_ascii=False,indent=2))
    else:
        navigation=result["navigation"]
        previous=navigation["previous_stage"]
        current_stage=navigation["current_stage"]
        print(
            "Previous stage: "
            + (f"{previous['label']} (S{previous['position']})" if previous else "なし")
        )
        print(f"Current stage: {current_stage['label']} (S{current_stage['position']})")
        print(f"Progress: {navigation['progress']['label']}")
        q=result["question"]
        print(f"Question: {q.get('question')}")
        print(f"Reason: {q.get('reason')}")
        print(f"Recommended answer: {q.get('recommended_answer') or '保留'}")
        print(f"Recommendation reason: {q.get('recommendation_reason')}")
        print(f"Answer guide: {q.get('answer_guide')}")
    return 0


if __name__=="__main__":
    raise SystemExit(main())
