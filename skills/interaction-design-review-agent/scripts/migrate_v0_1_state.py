#!/usr/bin/env python3
"""Migrate an interaction-design-decision-coach v0.1 state to v1.0."""
from __future__ import annotations
import argparse, json
from pathlib import Path
from typing import Any

STAGES=["business_workflow","decision_flow","decision_table","design_principles",
        "contradiction_check","state_machine","information_architecture","ui_behavior"]

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("old")
    ap.add_argument("new")
    args=ap.parse_args()
    old=json.loads(Path(args.old).read_text(encoding="utf-8"))
    project=old.get("project",{})
    new: dict[str,Any]={
      "schema_version":"1.0",
      "project":{
        "name":project.get("name",""),
        "scope":project.get("scope",""),
        "status":project.get("status","draft"),
        "success_conditions":[
          {"id":"SC1","statement":project.get("success_condition",""),"verification":"","status":"provisional"}
        ] if project.get("success_condition") else []
      },
      "pipeline":{
        "current_stage":"business_workflow",
        "stages":[{"id":s,"status":"not_started","review_notes":[]} for s in STAGES]
      },
      "facts":[],
      "actors":old.get("actors",[]),
      "constraints":old.get("constraints",[]),
      "business_workflow":{"start_event":"","end_event":"","steps":[]},
      "decisions":[],
      "decision_table":{"conditions":[],"actions":[],"cases":[]},
      "principles":old.get("principles",[]),
      "contradictions":[],
      "state_machine":{
        "initial_state_id": (old.get("states") or [{}])[0].get("id") if old.get("states") else "",
        "states":[],
        "transitions":[]
      },
      "information_architecture":{"nodes":[],"relationships":[]},
      "ui_behaviors":[],
      "questions":[],
      "assumptions":old.get("assumptions",[]),
      "traceability":[]
    }
    for d in old.get("decisions",[]):
        opts=d.get("options",[])
        option_objs=[{"id":f"O{i+1}","label":str(v),"effects":{}} for i,v in enumerate(opts)]
        selected=d.get("selected")
        selected_id=None
        for o in option_objs:
            if o["label"]==selected: selected_id=o["id"]
        nd={
          "id":d.get("id"),"question":d.get("question",""),"status":d.get("status","unresolved"),
          "options":option_objs,"selected_option_id":selected_id,"owner":d.get("owner","user"),
          "applies_when":d.get("applies_when",""),"reversible":d.get("reversible",True),
          "cost_impact":"","latency_impact":"","risk":"","rationale":d.get("rationale",""),
          "principle_ids":d.get("principle_ids",[]),"workflow_step_ids":[],"tags":[]
        }
        new["decisions"].append(nd)
    for s in old.get("states",[]):
        new["state_machine"]["states"].append({
          "id":s.get("id"),"name":s.get("name",""),"type":"normal",
          "entry_condition":s.get("entry_condition",""),"visible":[],"exit_condition":s.get("exit_condition","")
        })
    for t in old.get("transitions",[]):
        new["state_machine"]["transitions"].append({
          "id":t.get("id"),"from_state_id":t.get("from"),"to_state_id":t.get("to"),
          "event":t.get("event",""),"guard":t.get("guard",""),"decision_ids":[],
          "workflow_step_ids":[],"recovery":False,"assumption":t.get("assumption",False)
        })
    for c in old.get("contradictions",[]):
        new["contradictions"].append({
          "id":c.get("id"),"rule_id":"C01","severity":c.get("severity","warning"),
          "stage":"contradiction_check","evidence_refs":c.get("decision_ids",[]),
          "reason":c.get("reason",""),"status":c.get("status","open"),
          "resolution":"","accepted_by":""
        })
    Path(args.new).write_text(json.dumps(new,ensure_ascii=False,indent=2),encoding="utf-8")
    print(f"Wrote {args.new}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
