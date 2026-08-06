#!/usr/bin/env python3
"""Validate a design-case JSON for the Interaction Design Review Agent.

Usage:
    python3 validate_design_case.py path/to/design-case.json [--json]

Exit codes:
    0: no blocking issue
    1: blocking issue found
    2: usage or parse error
"""
from __future__ import annotations

import argparse
import json
from collections import defaultdict, deque
from pathlib import Path
from typing import Any

TOP_LEVEL = [
    "schema_version","project","pipeline","actors","business_understanding",
    "business_workflow","decision_requirements","target_value_loop",
    "decisions","decision_table","principles","contradictions",
    "state_machine","information_architecture","ui_behaviors",
    "questions","assumptions"
]
VALID_DECISION_STATUS = {"unresolved","provisional","confirmed","rejected"}
VALID_OWNER = {"user","system","expert","hybrid"}
VALID_SEVERITY = {"note","warning","blocking"}
VALID_CONTRADICTION_STATUS = {"open","resolved","accepted_risk"}
VALID_LOGIC_TYPE = {
    "simple_rule","flowchart","decision_table","boundary_table","expert_judgment"
}
VALID_ANSWER_TYPE = {"yes_no","single_choice","free_text"}

def load(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"ERROR file not found: {path}")
    except json.JSONDecodeError as e:
        raise SystemExit(f"ERROR invalid JSON line {e.lineno} column {e.colno}: {e.msg}")
    if not isinstance(data, dict):
        raise SystemExit("ERROR top-level JSON must be an object")
    return data

def add(issues: list[dict[str,str]], severity: str, code: str, message: str) -> None:
    issues.append({"severity":severity,"code":code,"message":message})

def index_ids(items: Any, label: str, issues: list[dict[str,str]]) -> dict[str,dict[str,Any]]:
    if not isinstance(items, list):
        add(issues,"blocking","STRUCTURE",f"{label} must be an array")
        return {}
    out: dict[str,dict[str,Any]] = {}
    for i,item in enumerate(items):
        if not isinstance(item, dict):
            add(issues,"blocking","STRUCTURE",f"{label}[{i}] must be an object")
            continue
        iid = item.get("id")
        if not isinstance(iid,str) or not iid.strip():
            add(issues,"blocking","MISSING_ID",f"{label}[{i}] has no id")
            continue
        if iid in out:
            add(issues,"blocking","DUPLICATE_ID",f"duplicate {label} id: {iid}")
        out[iid] = item
    return out

def detect_effect_conflicts(decisions: dict[str,dict[str,Any]], issues: list[dict[str,str]]) -> None:
    by_scope: dict[tuple[str,str], list[tuple[str,Any]]] = defaultdict(list)
    for did,d in decisions.items():
        if d.get("status") != "confirmed":
            continue
        selected = d.get("selected_option_id")
        options = {o.get("id"):o for o in d.get("options",[]) if isinstance(o,dict)}
        option = options.get(selected)
        if not option:
            continue
        scope = str(d.get("applies_when","")).strip()
        effects = option.get("effects",{})
        if not isinstance(effects,dict):
            continue
        for key,value in effects.items():
            by_scope[(scope,key)].append((did,value))
    for (scope,key), vals in by_scope.items():
        unique = {json.dumps(v,ensure_ascii=False,sort_keys=True) for _,v in vals}
        if len(unique) > 1:
            detail = ", ".join(f"{did}={value!r}" for did,value in vals)
            add(issues,"blocking","EFFECT_CONFLICT",
                f"confirmed decisions conflict for effect '{key}' under '{scope}': {detail}")

def reachable_states(initial: str, transitions: list[dict[str,Any]]) -> set[str]:
    graph: dict[str,list[str]] = defaultdict(list)
    for t in transitions:
        graph[str(t.get("from_state_id"))].append(str(t.get("to_state_id")))
    seen: set[str] = set()
    q = deque([initial])
    while q:
        n=q.popleft()
        if n in seen: continue
        seen.add(n)
        q.extend(graph.get(n,[]))
    return seen

def validate_workflow_steps(
    steps: Any,
    label: str,
    start_step_id: str,
    actor_idx: dict[str,dict[str,Any]],
    issues: list[dict[str,str]],
) -> dict[str,dict[str,Any]]:
    step_idx = index_ids(steps,label,issues)
    if len(step_idx) < 2:
        add(issues,"blocking","WORKFLOW_STEPS",f"{label} requires at least two steps")
    if start_step_id not in step_idx:
        add(issues,"blocking","WORKFLOW_BOUNDARY",f"{label} start step {start_step_id!r} does not exist")
    for sid,step in step_idx.items():
        aid=step.get("actor_id")
        if aid not in actor_idx:
            add(issues,"blocking","BROKEN_REF",f"{label} {sid} references missing actor {aid!r}")
        if not str(step.get("action","")).strip():
            add(issues,"blocking","WORKFLOW_MEANING",f"{label} {sid} has no action")
        if not step.get("input"):
            add(issues,"blocking","WORKFLOW_MEANING",f"{label} {sid} has no input")
        if not step.get("output"):
            add(issues,"blocking","WORKFLOW_MEANING",f"{label} {sid} has no output")
        for nxt in step.get("next_step_ids",[]) or []:
            if nxt not in step_idx:
                add(issues,"blocking","BROKEN_REF",f"{label} {sid} references missing next step {nxt}")
                continue
            current_output=set(step.get("output",[]) or [])
            next_input=set(step_idx[nxt].get("input",[]) or [])
            if current_output.isdisjoint(next_input):
                add(issues,"blocking","WORKFLOW_HANDOFF",f"{label} {sid} output does not feed {nxt} input")
    if start_step_id in step_idx:
        reachable=reachable_states(start_step_id,[
            {"from_state_id":sid,"to_state_id":nxt}
            for sid,step in step_idx.items()
            for nxt in (step.get("next_step_ids",[]) or [])
            if nxt in step_idx
        ])
        for sid in step_idx:
            if sid not in reachable:
                add(issues,"blocking","WORKFLOW_REACHABILITY",f"{label} {sid} is unreachable from {start_step_id}")
    if step_idx and not any(not (step.get("next_step_ids",[]) or []) for step in step_idx.values()):
        add(issues,"blocking","WORKFLOW_BOUNDARY",f"{label} has no terminal step")
    return step_idx

def validate(data: dict[str,Any]) -> list[dict[str,str]]:
    issues: list[dict[str,str]] = []
    if data.get("schema_version") != "2.0":
        add(issues,"blocking","SCHEMA_VERSION","schema_version must be 2.0")
    for key in TOP_LEVEL:
        if key not in data:
            add(issues,"blocking","MISSING_TOP_LEVEL",f"missing top-level key: {key}")

    business_stage=next(
        (
            stage for stage in data.get("pipeline",{}).get("stages",[])
            if stage.get("id")=="business_understanding"
        ),
        {},
    )
    if business_stage.get("status")!="approved":
        add(issues,"blocking","S1_APPROVAL","business understanding is not approved")
    if business_stage.get("approved_by") not in {"user","delegated_by_user"}:
        add(issues,"blocking","S1_APPROVAL","business understanding has no valid human approver")
    if not str(business_stage.get("approval_evidence","")).strip():
        add(issues,"blocking","S1_APPROVAL","business understanding has no approval evidence")

    project = data.get("project",{})
    if not str(project.get("name","")).strip():
        add(issues,"warning","PROJECT_NAME","project.name is empty")
    if not str(project.get("scope","")).strip():
        add(issues,"blocking","PROJECT_SCOPE","project.scope is empty")
    sc = project.get("success_conditions",[])
    sc_idx = index_ids(sc,"success_condition",issues)
    if not sc_idx:
        add(issues,"blocking","SUCCESS_CONDITION","at least one success condition is required")
    for scid,condition in sc_idx.items():
        if not str(condition.get("statement","")).strip():
            add(issues,"blocking","SUCCESS_CONDITION",f"success condition {scid} has no statement")
        if not str(condition.get("verification","")).strip():
            add(issues,"blocking","SUCCESS_CONDITION",f"success condition {scid} has no verification")

    actor_idx = index_ids(data.get("actors",[]),"actor",issues)
    if not actor_idx:
        add(issues,"blocking","ACTOR","at least one actor is required")
    for aid,actor in actor_idx.items():
        for key in ("name","role","goal"):
            if not str(actor.get(key,"")).strip():
                add(issues,"blocking","ACTOR_MEANING",f"actor {aid} has no {key}")
        if not actor.get("responsibilities"):
            add(issues,"blocking","ACTOR_MEANING",f"actor {aid} has no responsibilities")

    understanding = data.get("business_understanding",{})
    for key in ("purpose","teach_back"):
        if not str(understanding.get(key,"")).strip():
            add(issues,"blocking","BUSINESS_UNDERSTANDING",f"business_understanding.{key} is empty")
    for key in ("scope_in","scope_out"):
        if not understanding.get(key):
            add(issues,"blocking","BUSINESS_UNDERSTANDING",f"business_understanding.{key} is empty")

    workflow = data.get("business_workflow",{})
    if not str(workflow.get("start_event","")).strip():
        add(issues,"blocking","WORKFLOW_BOUNDARY","business workflow has no start event")
    if not str(workflow.get("end_event","")).strip():
        add(issues,"blocking","WORKFLOW_BOUNDARY","business workflow has no end event")
    step_idx = validate_workflow_steps(
        workflow.get("steps",[]),"workflow_step",workflow.get("start_step_id",""),actor_idx,issues
    )

    requirements = data.get("decision_requirements",{})
    requirement_idx = index_ids(requirements.get("items",[]),"decision_requirement",issues)
    if not requirement_idx and not requirements.get("confirmed_none",False):
        add(issues,"blocking","DECISION_REQUIREMENT","decision requirements are not confirmed")
    if requirement_idx and requirements.get("confirmed_none",False):
        add(issues,"blocking","DECISION_REQUIREMENT","confirmed_none conflicts with decision requirement items")
    for rid,requirement in requirement_idx.items():
        for key in ("question","business_reason","trigger","failure_impact"):
            if not str(requirement.get(key,"")).strip():
                add(issues,"blocking","DECISION_REQUIREMENT",f"decision requirement {rid} has no {key}")
        if not requirement.get("evidence"):
            add(issues,"blocking","DECISION_REQUIREMENT",f"decision requirement {rid} has no evidence")
        for wid in requirement.get("workflow_step_ids",[]) or []:
            if wid not in step_idx:
                add(issues,"blocking","BROKEN_REF",f"decision requirement {rid} references missing workflow step {wid}")

    value_loop = data.get("target_value_loop",{})
    if not str(value_loop.get("start_event","")).strip():
        add(issues,"blocking","VALUE_LOOP_BOUNDARY","target value loop has no start event")
    if not str(value_loop.get("value_outcome","")).strip():
        add(issues,"blocking","VALUE_LOOP_BOUNDARY","target value loop has no value outcome")
    value_step_idx = validate_workflow_steps(
        value_loop.get("steps",[]),"value_loop_step",value_loop.get("start_step_id",""),actor_idx,issues
    )
    for vsid,value_step in value_step_idx.items():
        for rid in value_step.get("decision_requirement_ids",[]) or []:
            if rid not in requirement_idx:
                add(issues,"blocking","BROKEN_REF",f"value loop step {vsid} references missing decision requirement {rid}")

    principle_idx = index_ids(data.get("principles",[]),"principle",issues)
    priorities: dict[int,str] = {}
    for pid,p in principle_idx.items():
        pr=p.get("priority")
        if not isinstance(pr,int) or pr < 1:
            add(issues,"warning","PRINCIPLE_PRIORITY",f"principle {pid} has invalid priority")
        elif pr in priorities:
            add(issues,"warning","PRINCIPLE_PRIORITY",f"principles {priorities[pr]} and {pid} share priority {pr}")
        else:
            priorities[pr]=pid
        for scid in p.get("success_condition_ids",[]) or []:
            if scid not in sc_idx:
                add(issues,"blocking","BROKEN_REF",f"principle {pid} references missing success condition {scid}")

    decision_idx = index_ids(data.get("decisions",[]),"decision",issues)
    for did,d in decision_idx.items():
        if d.get("status") not in VALID_DECISION_STATUS:
            add(issues,"warning","DECISION_STATUS",f"decision {did} has invalid status")
        if d.get("owner") not in VALID_OWNER:
            add(issues,"warning","DECISION_OWNER",f"decision {did} has invalid owner")
        rid=d.get("requirement_id")
        if rid not in requirement_idx:
            add(issues,"blocking","BROKEN_REF",f"decision {did} references missing decision requirement {rid!r}")
        if d.get("logic_type") not in VALID_LOGIC_TYPE:
            add(issues,"blocking","DECISION_LOGIC",f"decision {did} has invalid logic_type")
        if not d.get("evidence"):
            add(issues,"blocking","DECISION_EVIDENCE",f"decision {did} has no evidence")
        if not str(d.get("risk","")).strip():
            add(issues,"blocking","DECISION_RISK",f"decision {did} has no failure impact")
        options = {o.get("id"):o for o in d.get("options",[]) if isinstance(o,dict)}
        selected=d.get("selected_option_id")
        if d.get("status") in {"confirmed","provisional"} and not selected:
            add(issues,"blocking","DECISION_SELECTION",f"decision {did} is {d.get('status')} but no option selected")
        if selected and selected not in options:
            add(issues,"blocking","DECISION_SELECTION",f"decision {did} selects missing option {selected}")
        for pid in d.get("principle_ids",[]) or []:
            if pid not in principle_idx:
                add(issues,"blocking","BROKEN_REF",f"decision {did} references missing principle {pid}")
        if d.get("status")=="confirmed" and not d.get("principle_ids"):
            add(issues,"warning","TRACEABILITY",f"confirmed decision {did} has no principle")
        for wid in d.get("workflow_step_ids",[]) or []:
            if wid not in step_idx:
                add(issues,"blocking","BROKEN_REF",f"decision {did} references missing workflow step {wid}")
        for vsid in d.get("target_value_step_ids",[]) or []:
            if vsid not in value_step_idx:
                add(issues,"blocking","BROKEN_REF",f"decision {did} references missing value loop step {vsid}")
    detect_effect_conflicts(decision_idx,issues)
    covered_requirement_ids={d.get("requirement_id") for d in decision_idx.values()}
    for rid in requirement_idx:
        if rid not in covered_requirement_ids:
            add(issues,"blocking","DECISION_COVERAGE",f"decision requirement {rid} has no disposition")

    # Decision Table is an optional representation for multi-condition decisions.
    dt=data.get("decision_table",{})
    cond_idx=index_ids(dt.get("conditions",[]),"condition",issues)
    action_idx=index_ids(dt.get("actions",[]),"action",issues)
    case_idx=index_ids(dt.get("cases",[]),"case",issues)
    table_required={did for did,d in decision_idx.items() if d.get("logic_type")=="decision_table"}
    if table_required and (not cond_idx or not action_idx or not case_idx):
        add(issues,"blocking","DECISION_TABLE","conditions, actions, and cases are required")
    table_targets=set(dt.get("applies_to_decision_ids",[]) or [])
    for did in table_required-table_targets:
        add(issues,"blocking","DECISION_TABLE",f"decision table does not cover {did}")
    for did in table_targets:
        if did not in decision_idx:
            add(issues,"blocking","BROKEN_REF",f"decision table references missing decision {did}")
    for cid,c in case_idx.items():
        for key,val in (c.get("conditions",{}) or {}).items():
            if key not in cond_idx:
                add(issues,"blocking","BROKEN_REF",f"case {cid} references missing condition {key}")
            if val not in {"Y","N","-"}:
                add(issues,"warning","DECISION_TABLE_VALUE",f"case {cid} condition {key} has {val!r}")
        for key,val in (c.get("actions",{}) or {}).items():
            if key not in action_idx:
                add(issues,"blocking","BROKEN_REF",f"case {cid} references missing action {key}")
            if val not in {"X","-"}:
                add(issues,"warning","DECISION_TABLE_VALUE",f"case {cid} action {key} has {val!r}")

    contradiction_idx=index_ids(data.get("contradictions",[]),"contradiction",issues)
    for xid,x in contradiction_idx.items():
        if x.get("severity") not in VALID_SEVERITY:
            add(issues,"warning","CONTRADICTION_SEVERITY",f"contradiction {xid} has invalid severity")
        if x.get("status") not in VALID_CONTRADICTION_STATUS:
            add(issues,"warning","CONTRADICTION_STATUS",f"contradiction {xid} has invalid status")
        if x.get("severity")=="blocking" and x.get("status")=="open":
            add(issues,"blocking","OPEN_BLOCKING",f"open blocking contradiction: {xid}")

    sm=data.get("state_machine",{})
    state_idx=index_ids(sm.get("states",[]),"state",issues)
    transition_idx=index_ids(sm.get("transitions",[]),"transition",issues)
    initial=sm.get("initial_state_id")
    if initial not in state_idx:
        add(issues,"blocking","INITIAL_STATE",f"initial state {initial!r} does not exist")
    for tid,t in transition_idx.items():
        src=t.get("from_state_id"); dst=t.get("to_state_id")
        if src not in state_idx:
            add(issues,"blocking","BROKEN_REF",f"transition {tid} missing source {src}")
        if dst not in state_idx:
            add(issues,"blocking","BROKEN_REF",f"transition {tid} missing target {dst}")
        for did in t.get("decision_ids",[]) or []:
            if did not in decision_idx:
                add(issues,"blocking","BROKEN_REF",f"transition {tid} references missing decision {did}")
    if initial in state_idx:
        reachable=reachable_states(initial,list(transition_idx.values()))
        for sid in state_idx:
            if sid not in reachable:
                add(issues,"warning","UNREACHABLE_STATE",f"state {sid} is unreachable from {initial}")

    ia=data.get("information_architecture",{})
    ia_idx=index_ids(ia.get("nodes",[]),"ia_node",issues)
    for iid,n in ia_idx.items():
        parent=n.get("parent_id")
        if parent is not None and parent not in ia_idx:
            add(issues,"blocking","BROKEN_REF",f"IA node {iid} references missing parent {parent}")
        for sid in n.get("state_ids",[]) or []:
            if sid not in state_idx:
                add(issues,"blocking","BROKEN_REF",f"IA node {iid} references missing state {sid}")
        for did in n.get("decision_ids",[]) or []:
            if did not in decision_idx:
                add(issues,"blocking","BROKEN_REF",f"IA node {iid} references missing decision {did}")

    ui_idx=index_ids(data.get("ui_behaviors",[]),"ui_behavior",issues)
    for uid,u in ui_idx.items():
        if not u.get("state_ids"):
            add(issues,"warning","TRACEABILITY",f"UI behavior {uid} has no state")
        if not u.get("decision_ids"):
            add(issues,"warning","TRACEABILITY",f"UI behavior {uid} has no decision")
        for sid in u.get("state_ids",[]) or []:
            if sid not in state_idx:
                add(issues,"blocking","BROKEN_REF",f"UI behavior {uid} references missing state {sid}")
        for did in u.get("decision_ids",[]) or []:
            if did not in decision_idx:
                add(issues,"blocking","BROKEN_REF",f"UI behavior {uid} references missing decision {did}")
        for pid in u.get("principle_ids",[]) or []:
            if pid not in principle_idx:
                add(issues,"blocking","BROKEN_REF",f"UI behavior {uid} references missing principle {pid}")
        for iid in u.get("ia_node_ids",[]) or []:
            if iid not in ia_idx:
                add(issues,"blocking","BROKEN_REF",f"UI behavior {uid} references missing IA node {iid}")

    question_idx=index_ids(data.get("questions",[]),"question",issues)
    for qid,question in question_idx.items():
        if question.get("status") != "open":
            continue
        answer_type=question.get("answer_type")
        recommended=str(question.get("recommended_answer","")).strip().lower()
        recommendation_reason=str(question.get("recommendation_reason","")).strip()
        answer_guide=str(question.get("answer_guide","")).strip()
        if answer_type not in VALID_ANSWER_TYPE:
            add(issues,"blocking","QUESTION_DECISION_SUPPORT",f"open question {qid} has invalid answer_type")
            continue
        if not recommendation_reason:
            add(issues,"blocking","QUESTION_DECISION_SUPPORT",f"open question {qid} has no recommendation reason")
        if not answer_guide:
            add(issues,"blocking","QUESTION_DECISION_SUPPORT",f"open question {qid} has no answer guide")
        if answer_type == "yes_no":
            if recommended not in {"y","n"}:
                add(issues,"blocking","QUESTION_DECISION_SUPPORT",f"yes/no question {qid} must recommend y or n")
            guide=answer_guide.lower()
            if "y" not in guide or "n" not in guide:
                add(issues,"blocking","QUESTION_DECISION_SUPPORT",f"yes/no question {qid} answer guide must show y and n")
        if answer_type == "single_choice" and not recommended:
            add(issues,"blocking","QUESTION_DECISION_SUPPORT",f"single-choice question {qid} has no recommended answer")
    index_ids(data.get("assumptions",[]),"assumption",issues)
    return issues

def main() -> int:
    parser=argparse.ArgumentParser()
    parser.add_argument("path")
    parser.add_argument("--json",action="store_true")
    args=parser.parse_args()
    data=load(Path(args.path))
    issues=validate(data)
    blocking=[i for i in issues if i["severity"]=="blocking"]
    if args.json:
        print(json.dumps({"blocking_count":len(blocking),"issues":issues},ensure_ascii=False,indent=2))
    else:
        print(f"Project: {data.get('project',{}).get('name','(unnamed)')}")
        print(f"Blocking: {len(blocking)}; total issues: {len(issues)}")
        for i in issues:
            print(f"- {i['severity'].upper()} {i['code']}: {i['message']}")
        if not issues:
            print("PASS: no structural or deterministic consistency issues")
    return 1 if blocking else 0

if __name__=="__main__":
    raise SystemExit(main())
