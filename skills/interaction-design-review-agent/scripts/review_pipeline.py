#!/usr/bin/env python3
"""Review stage-gate readiness for a design-case JSON."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


STAGES = [
    ("business_understanding", "Business Understanding"),
    ("decision_requirements", "Decision Requirements"),
    ("target_value_loop", "Target Value Loop"),
    ("decision_specification", "Decision Specification"),
    ("design_principles", "Design Principles"),
    ("contradiction_check", "Contradiction Check"),
    ("state_machine", "State Machine"),
    ("information_architecture", "Information Architecture"),
    ("ui_behavior", "UI Behavior"),
]


def load(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def nonempty(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def pipeline_stage(data: dict[str, Any], stage_id: str) -> dict[str, Any]:
    for stage in data.get("pipeline", {}).get("stages", []):
        if stage.get("id") == stage_id:
            return stage
    return {}


def check_steps(
    steps: list[dict[str, Any]],
    actor_ids: set[str],
    label: str,
    start_step_id: str,
) -> list[str]:
    blockers: list[str] = []
    if len(steps) < 2:
        return [f"{label}が2件未満"]
    step_ids = {step.get("id") for step in steps}
    if start_step_id not in step_ids:
        blockers.append(f"{label}の開始ステップが不明")
    for step in steps:
        step_id = step.get("id", "(IDなし)")
        if step.get("actor_id") not in actor_ids:
            blockers.append(f"{step_id} のアクターが不明")
        if not nonempty(step.get("action")):
            blockers.append(f"{step_id} の行為が未定義")
        if not step.get("input"):
            blockers.append(f"{step_id} の入力が未定義")
        if not step.get("output"):
            blockers.append(f"{step_id} の出力が未定義")
    return blockers


def checks(data: dict[str, Any]) -> dict[str, list[str]]:
    project = data.get("project", {})
    actors = data.get("actors", [])
    actor_ids = {actor.get("id") for actor in actors}
    stages: dict[str, list[str]] = {stage_id: [] for stage_id, _ in STAGES}

    business = stages["business_understanding"]
    understanding = data.get("business_understanding", {})
    workflow = data.get("business_workflow", {})
    if not nonempty(project.get("scope")):
        business.append("project.scopeが未定義")
    success_conditions = project.get("success_conditions", [])
    if not success_conditions:
        business.append("成功条件がない")
    for condition in success_conditions:
        condition_id = condition.get("id", "(IDなし)")
        if not nonempty(condition.get("statement")):
            business.append(f"{condition_id} の成功状態が未定義")
        if not nonempty(condition.get("verification")):
            business.append(f"{condition_id} の検証方法が未定義")
    if not actors:
        business.append("アクターがない")
    for actor in actors:
        actor_id = actor.get("id", "(IDなし)")
        if not nonempty(actor.get("name")):
            business.append(f"{actor_id} の名前が未定義")
        if not nonempty(actor.get("role")):
            business.append(f"{actor_id} の役割が未定義")
        if not nonempty(actor.get("goal")):
            business.append(f"{actor_id} の目的が未定義")
        if not actor.get("responsibilities"):
            business.append(f"{actor_id} の責任が未定義")
    if not nonempty(understanding.get("purpose")):
        business.append("業務目的が未定義")
    if not understanding.get("scope_in"):
        business.append("対象範囲内が未定義")
    if not understanding.get("scope_out"):
        business.append("対象範囲外が未定義")
    if not nonempty(understanding.get("teach_back")):
        business.append("agentの業務理解要約がない")
    if not nonempty(workflow.get("start_event")):
        business.append("現行業務の開始契機が未定義")
    if not nonempty(workflow.get("end_event")):
        business.append("現行業務の終了状態が未定義")
    business.extend(
        check_steps(
            workflow.get("steps", []), actor_ids, "現行業務ステップ", workflow.get("start_step_id", "")
        )
    )
    business_stage = pipeline_stage(data, "business_understanding")
    if business_stage.get("status") != "approved":
        business.append("ユーザー承認がない")
    if business_stage.get("approved_by") not in {"user", "delegated_by_user"}:
        business.append("承認主体がユーザーまたは明示委任ではない")
    if not nonempty(business_stage.get("approval_evidence")):
        business.append("承認根拠が記録されていない")

    requirements_stage = stages["decision_requirements"]
    requirements = data.get("decision_requirements", {})
    requirement_items = requirements.get("items", [])
    if not requirement_items and not requirements.get("confirmed_none", False):
        requirements_stage.append("必要な判断の有無が未確認")
    for requirement in requirement_items:
        requirement_id = requirement.get("id", "(IDなし)")
        for key, label in (
            ("question", "判断内容"),
            ("business_reason", "業務上の理由"),
            ("trigger", "発生条件"),
            ("failure_impact", "誤判断の影響"),
        ):
            if not nonempty(requirement.get(key)):
                requirements_stage.append(f"{requirement_id} の{label}が未定義")
        if not requirement.get("evidence"):
            requirements_stage.append(f"{requirement_id} の判断根拠が未定義")

    value_stage = stages["target_value_loop"]
    value_loop = data.get("target_value_loop", {})
    if not nonempty(value_loop.get("start_event")):
        value_stage.append("価値ループの開始契機が未定義")
    if not nonempty(value_loop.get("value_outcome")):
        value_stage.append("価値獲得状態が未定義")
    value_stage.extend(
        check_steps(
            value_loop.get("steps", []),
            actor_ids,
            "価値ループのステップ",
            value_loop.get("start_step_id", ""),
        )
    )

    specification_stage = stages["decision_specification"]
    decisions = data.get("decisions", [])
    requirement_ids = {item.get("id") for item in requirement_items}
    covered_requirement_ids = {decision.get("requirement_id") for decision in decisions}
    for requirement_id in requirement_ids - covered_requirement_ids:
        specification_stage.append(f"{requirement_id} の扱いが未定義")
    for decision in decisions:
        decision_id = decision.get("id", "(IDなし)")
        if decision.get("requirement_id") not in requirement_ids:
            specification_stage.append(f"{decision_id} が必要判断を参照していない")
        for key, label in (
            ("question", "判断内容"),
            ("applies_when", "発生条件"),
            ("owner", "判断主体"),
            ("risk", "誤判断の影響"),
        ):
            if not nonempty(decision.get(key)):
                specification_stage.append(f"{decision_id} の{label}が未定義")
        if not decision.get("evidence"):
            specification_stage.append(f"{decision_id} の判断根拠が未定義")
        if not decision.get("options"):
            specification_stage.append(f"{decision_id} の結果候補がない")
        if decision.get("logic_type") not in {
            "simple_rule",
            "flowchart",
            "decision_table",
            "boundary_table",
            "expert_judgment",
        }:
            specification_stage.append(f"{decision_id} の論理表現が未定義")
    table_required_ids = {
        decision.get("id") for decision in decisions if decision.get("logic_type") == "decision_table"
    }
    if table_required_ids:
        table = data.get("decision_table", {})
        for key in ("conditions", "actions", "cases"):
            if not table.get(key):
                specification_stage.append(f"Decision Tableの{key}がない")
        table_targets = set(table.get("applies_to_decision_ids", []))
        for decision_id in table_required_ids - table_targets:
            specification_stage.append(f"{decision_id} をDecision Tableが参照していない")

    principles_stage = stages["design_principles"]
    principles = data.get("principles", [])
    if len(principles) < 2:
        principles_stage.append("原則が2件未満")
    priorities = [principle.get("priority") for principle in principles]
    if len(priorities) != len(set(priorities)):
        principles_stage.append("原則の優先順位が重複")
    for principle in principles:
        if not nonempty(principle.get("verification")):
            principles_stage.append(f"{principle.get('id')} 検証方法なし")

    contradiction_stage = stages["contradiction_check"]
    for contradiction in data.get("contradictions", []):
        if contradiction.get("severity") == "blocking" and contradiction.get("status") == "open":
            contradiction_stage.append(
                f"Open Blocking {contradiction.get('id')}: {contradiction.get('reason', '')}"
            )

    state_stage = stages["state_machine"]
    state_machine = data.get("state_machine", {})
    states = state_machine.get("states", [])
    transitions = state_machine.get("transitions", [])
    state_ids = {state.get("id") for state in states}
    if state_machine.get("initial_state_id") not in state_ids:
        state_stage.append("初期状態がない")
    if len(states) < 2:
        state_stage.append("状態が2件未満")
    if not transitions:
        state_stage.append("遷移がない")
    tags = {tag for decision in decisions for tag in (decision.get("tags") or [])}
    state_types = {state.get("type") for state in states}
    if "long_running_action" in tags and "processing" not in state_types:
        state_stage.append("長時間処理にprocessing状態がない")
    if "long_running_action" in tags and "failure" not in state_types:
        state_stage.append("長時間処理にfailure状態がない")

    ia_stage = stages["information_architecture"]
    nodes = data.get("information_architecture", {}).get("nodes", [])
    if not nodes:
        ia_stage.append("IAノードがない")
    for node in nodes:
        if not node.get("state_ids") and not node.get("decision_ids"):
            ia_stage.append(f"{node.get('id')} に状態・決定の参照がない")

    ui_stage = stages["ui_behavior"]
    ui_behaviors = data.get("ui_behaviors", [])
    if not ui_behaviors:
        ui_stage.append("UI挙動がない")
    for behavior in ui_behaviors:
        required = ["display_condition", "user_action", "system_result", "feedback", "recovery"]
        missing = [key for key in required if not nonempty(behavior.get(key))]
        if missing:
            ui_stage.append(f"{behavior.get('id')} 未定義: {', '.join(missing)}")
        if not behavior.get("decision_ids") or not behavior.get("state_ids"):
            ui_stage.append(f"{behavior.get('id')} トレーサビリティ不足")
    return stages


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    data = load(Path(args.path))
    blockers = checks(data)
    prior_ready = True
    rows = []
    for stage_id, label in STAGES:
        own_blockers = blockers[stage_id]
        if not prior_ready:
            status = "blocked_by_upstream"
        elif own_blockers:
            status = "blocked"
            prior_ready = False
        else:
            status = "ready"
        rows.append({"id": stage_id, "label": label, "status": status, "blockers": own_blockers})
    next_stage = next(
        (row["id"] for row in rows if row["status"] in {"blocked", "blocked_by_upstream"}),
        None,
    )
    if args.json:
        print(json.dumps({"stages": rows, "next_stage": next_stage}, ensure_ascii=False, indent=2))
    else:
        print("| Stage | Status | Blockers |")
        print("|---|---|---|")
        for row in rows:
            print(f"| {row['label']} | {row['status']} | {'; '.join(row['blockers']) or '-'} |")
        print(f"\nNext stage: {next_stage or 'complete'}")
    return 1 if any(row["status"] == "blocked" for row in rows) else 0


if __name__ == "__main__":
    raise SystemExit(main())
