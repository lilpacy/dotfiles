#!/usr/bin/env python3
"""Select the single highest-priority open question for a design case."""
from __future__ import annotations
import argparse, json
from pathlib import Path
from typing import Any

STAGE_ORDER = {
 "business_understanding":1,"decision_requirements":2,"target_value_loop":3,
 "decision_specification":4,"design_principles":5,"contradiction_check":6,
 "state_machine":7,"information_architecture":8,"ui_behavior":9
}

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

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--json",action="store_true")
    args=ap.parse_args()
    data=json.loads(Path(args.path).read_text(encoding="utf-8"))
    current=data.get("pipeline",{}).get("current_stage","business_understanding")
    open_q=[q for q in data.get("questions",[]) if q.get("status")=="open"]
    # Blocking contradiction questions get an automatic boost.
    open_blocking={c.get("id") for c in data.get("contradictions",[]) if c.get("severity")=="blocking" and c.get("status")=="open"}
    scored=[]
    for q in open_q:
        score=int(q.get("priority",0))
        reason=str(q.get("reason",""))
        if any(cid and cid in reason for cid in open_blocking): score += 100
        if q.get("stage")==current: score += 20
        score -= abs(STAGE_ORDER.get(q.get("stage"),99)-STAGE_ORDER.get(current,1))*3
        scored.append((score,q))
    if scored:
        score,q=max(scored,key=lambda x:x[0])
        result={"source":"queue","score":score,"question":q}
    else:
        result={"source":"default","score":0,"question":{
            "id":None,"stage":current,"question":DEFAULTS.get(current,DEFAULTS["business_understanding"]),
            "priority":0,"reason":"現在ステージの既定質問","status":"suggested","answer":""
        }}
    if args.json:
        print(json.dumps(result,ensure_ascii=False,indent=2))
    else:
        q=result["question"]
        print(f"Stage: {q.get('stage')}")
        print(f"Question: {q.get('question')}")
        print(f"Reason: {q.get('reason')}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
