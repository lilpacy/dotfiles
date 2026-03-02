#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reclassify Agents vs Skills and (optionally) migrate files.

Design goals:
- safe: backups before writes
- conservative: best-effort reference update
- configurable: paths via YAML

Usage:
  python3 reclassify.py --config path/to/config.yaml --mode dry-run
  python3 reclassify.py --config path/to/config.yaml --mode apply

If config is missing, defaults + auto-detection will be used.
"""
from __future__ import annotations

import argparse
import datetime as dt
import re
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple, Optional

try:
    import yaml  # type: ignore
except Exception:
    yaml = None


# ---------------------------
# Helpers
# ---------------------------

def read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")

def write_text(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")

def now_stamp() -> str:
    return dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")

def find_existing_dir(candidates: List[str], repo: Path) -> Optional[Path]:
    for c in candidates:
        p = (repo / c).resolve()
        if p.exists() and p.is_dir():
            return p
    return None

def list_markdown_files(dirpath: Path) -> List[Path]:
    if not dirpath.exists():
        return []
    return [p for p in dirpath.rglob("*.md") if p.is_file()]

def is_skill_folder(p: Path) -> bool:
    return p.is_dir() and (p / "SKILL.md").exists()

def is_probably_agent_file(p: Path) -> bool:
    txt = read_text(p)
    if re.search(r"^##\s*(Role|役割)\b", txt, re.M):
        return True
    if re.search(r"\bsubagent\b", txt, re.I):
        return True
    return False

def is_probably_skill_file(p: Path) -> bool:
    txt = read_text(p)
    if re.search(r"^##\s*(Procedure|手順|Inputs|Outputs)\b", txt, re.M):
        return True
    if re.search(r"\bchecklist\b|\btemplate\b|\blint\b", txt, re.I):
        return True
    if p.name.upper() == "SKILL.MD":
        return True
    return False


# ---------------------------
# Scoring
# ---------------------------

SKILL_MARKERS = [
    r"\bprocedure\b", r"\bstep[s]?\b", r"\bchecklist\b", r"\btemplate\b",
    r"\binputs?\b", r"\boutputs?\b", r"\bformat\b", r"\bschema\b",
    r"\blint\b", r"\bconvert\b", r"\bgenerate\b", r"\bscaffold\b",
    r"\bzip\b", r"\bexport\b", r"\bvalidate\b",
    r"^##\s*(Procedure|手順|Inputs|Outputs|ガードレール|Guardrails)\b",
]
AGENT_MARKERS = [
    r"\brole\b", r"\bprinciple[s]?\b", r"\bhow i think\b",
    r"\btrade-?off\b", r"\bpriorit(ize|ise)\b", r"\bcritique\b",
    r"\breview(er)?\b", r"\bpersona\b", r"\bjudge\b", r"\bexplore\b",
    r"^##\s*(Role|役割|Operating principles|原則|How to respond|応答)\b",
]

@dataclass
class Item:
    path: Path
    current_type: str  # "agent" | "skill" | "unknown"
    name: str
    text: str

@dataclass
class Decision:
    recommended: str  # "agent" | "skill"
    confidence: float
    skill_score: float
    agent_score: float
    rationale: List[str]


def score_text(text: str) -> Tuple[float, float, List[str]]:
    skill_hits = []
    agent_hits = []
    for pat in SKILL_MARKERS:
        if re.search(pat, text, re.I | re.M):
            skill_hits.append(pat)
    for pat in AGENT_MARKERS:
        if re.search(pat, text, re.I | re.M):
            agent_hits.append(pat)

    skill_score = float(len(skill_hits))
    agent_score = float(len(agent_hits))

    # heading boosts
    if re.search(r"^##\s*(Procedure|手順)\b", text, re.M):
        skill_score += 2.0
    if re.search(r"^##\s*(Role|役割)\b", text, re.M):
        agent_score += 2.0

    # code fences / CLI instructions tend to be skill-ish
    if re.search(r"```(bash|sh|zsh|powershell|python|js|ts)\b", text, re.I):
        skill_score += 1.0

    # evaluative language tends to be agent-ish
    if re.search(r"\bshould\b|\bconsider\b|\btrade-?off\b", text, re.I):
        agent_score += 0.5

    rationale = []
    for pat in (skill_hits[:3] + agent_hits[:3]):
        rationale.append(pat)

    return skill_score, agent_score, rationale


def decide(item: Item) -> Decision:
    skill_score, agent_score, rationale = score_text(item.text)

    # mild prior towards current type
    if item.current_type == "skill":
        skill_score += 0.75
    elif item.current_type == "agent":
        agent_score += 0.75

    total = max(skill_score + agent_score, 1.0)
    conf = abs(skill_score - agent_score) / total
    confidence = min(1.0, 0.5 + conf)

    recommended = "skill" if skill_score >= agent_score else "agent"
    return Decision(
        recommended=recommended,
        confidence=confidence,
        skill_score=skill_score,
        agent_score=agent_score,
        rationale=rationale,
    )


# ---------------------------
# Rendering
# ---------------------------

def render_skill(name: str, original: str, low_conf: bool, embed_appendix: bool) -> str:
    note = "> ⚠️ Low-confidence conversion: please review this skill for intent/structure.\\n\\n" if low_conf else ""
    appendix = ""
    if embed_appendix:
        appendix = "\\n\\n---\\n\\n## Appendix: Original content\\n\\n" + original.strip() + "\\n"
    return f"""# {name}

{note}## Goal
Convert this capability into a reproducible workflow with clear inputs/outputs.

## When to use
Use when you want consistent, repeatable execution of this procedure.

## Inputs
- (define expected inputs)
- (files/paths)
- (constraints)

## Outputs
- (define produced artifacts)
- (report / files / diffs)

## Procedure
1. (step)
2. (step)
3. (step)

(Replace with the original procedure if present.)

## Guardrails
- Do not delete originals.
- Prefer dry-run then apply.
- Keep changes git-friendly.
{appendix}
"""


def render_agent(name: str, original: str, low_conf: bool, embed_appendix: bool) -> str:
    note = "> ⚠️ Low-confidence conversion: please review this subagent for role/intent.\\n\\n" if low_conf else ""
    appendix = ""
    if embed_appendix:
        appendix = "\\n\\n---\\n\\n## Appendix: Original content\\n\\n" + original.strip() + "\\n"
    return f"""# {name} (Subagent)

{note}## Role
A specialized reviewer/thinker that applies a consistent perspective.

## Objectives
- Evaluate the target with the agent's perspective
- Provide prioritized recommendations
- Highlight tradeoffs and risks

## Operating principles
- Be explicit about assumptions
- Prefer actionable feedback
- Offer options when uncertain

## When invoked
Invoke when judgment/exploration is required, not just execution of a fixed procedure.

## How to respond
Return structured feedback (bullets), include rationale, and propose next steps.
{appendix}
"""


# ---------------------------
# Discovery
# ---------------------------

def detect_items(repo: Path, agents_dirs: List[str], skills_dirs: List[str]) -> List[Item]:
    items: List[Item] = []

    # skills
    for sdir in skills_dirs:
        p = repo / sdir
        if not p.exists():
            continue

        # folder-based skills
        for child in p.iterdir():
            if is_skill_folder(child):
                sp = child / "SKILL.md"
                items.append(Item(path=child, current_type="skill", name=child.name, text=read_text(sp)))

        # loose markdown skills
        for md in list_markdown_files(p):
            if md.name.upper() == "SKILL.MD":
                continue
            # avoid files within a skill folder
            if (md.parent / "SKILL.md").exists():
                continue
            cur = "skill" if is_probably_skill_file(md) else "unknown"
            items.append(Item(path=md, current_type=cur, name=md.stem, text=read_text(md)))

    # agents
    for adir in agents_dirs:
        p = repo / adir
        if not p.exists():
            continue
        for md in list_markdown_files(p):
            items.append(Item(path=md, current_type="agent", name=md.stem, text=read_text(md)))

    # de-dup
    dedup: Dict[str, Item] = {}
    for it in items:
        dedup[str(it.path.resolve())] = it
    return list(dedup.values())


# ---------------------------
# Backup + Reference updates
# ---------------------------

def backup_paths(repo: Path, backup_root: Path, paths: List[Path]) -> None:
    for p in paths:
        rel = p.resolve().relative_to(repo.resolve())
        dest = backup_root / rel
        if p.is_dir():
            if dest.exists():
                shutil.rmtree(dest)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(p, dest)
        else:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, dest)


def update_references(repo: Path, scan_dirs: List[str], rename_map: Dict[str, str]) -> List[Path]:
    modified: List[Path] = []
    md_files: List[Path] = []
    for d in scan_dirs:
        p = repo / d
        if not p.exists():
            continue
        md_files.extend([x for x in p.rglob("*.md") if x.is_file()])

    for f in md_files:
        txt = read_text(f)
        new = txt
        for old, new_id in rename_map.items():
            # conservative replacements
            new = re.sub(rf"@{re.escape(old)}\b", f"@{new_id}", new)
            new = re.sub(rf"^(#{{1,6}}\s+){re.escape(old)}\b", rf"\1{new_id}", new, flags=re.M)
            new = re.sub(rf"\b{re.escape(old)}\b", new_id, new)

        if new != txt:
            write_text(f, new)
            modified.append(f)
    return modified


# ---------------------------
# Config
# ---------------------------

def load_config(config_path: Optional[Path]) -> dict:
    if config_path is None or not config_path.exists():
        return {}
    if yaml is None:
        raise RuntimeError("PyYAML is not installed. Install with: pip install pyyaml")
    return yaml.safe_load(read_text(config_path)) or {}


# ---------------------------
# Main
# ---------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", type=str, default="", help="Path to config.yaml (optional)")
    ap.add_argument("--mode", type=str, choices=["dry-run", "apply"], default="dry-run")
    args = ap.parse_args()

    repo = Path(".").resolve()
    cfg_path = Path(args.config).resolve() if args.config else None
    cfg = load_config(cfg_path)

    agents_dirs = cfg.get("paths", {}).get("agents_dirs", [".claude/agents", ".claude/subagents", "agents", "subagents"])
    skills_dirs = cfg.get("paths", {}).get("skills_dirs", [".claude/skills", "skills"])
    target_agents_dir = cfg.get("paths", {}).get("target_agents_dir", ".claude/agents")
    target_skills_dir = cfg.get("paths", {}).get("target_skills_dir", ".claude/skills")
    scan_dirs = cfg.get("paths", {}).get("reference_scan_dirs", ["."])

    low_policy = cfg.get("behavior", {}).get("low_confidence_policy", "convert")
    convert_threshold = float(cfg.get("behavior", {}).get("convert_threshold", 0.55))
    low_conf_threshold = float(cfg.get("behavior", {}).get("low_confidence_threshold", 0.65))
    update_refs = bool(cfg.get("behavior", {}).get("update_references", True))
    embed_appendix = bool(cfg.get("behavior", {}).get("embed_original_as_appendix", True))

    # auto-detect if missing
    if not any((repo / d).exists() for d in agents_dirs):
        det = find_existing_dir(agents_dirs, repo)
        if det:
            agents_dirs = [str(det.relative_to(repo))]
    if not any((repo / d).exists() for d in skills_dirs):
        det = find_existing_dir(skills_dirs, repo)
        if det:
            skills_dirs = [str(det.relative_to(repo))]

    items = detect_items(repo, agents_dirs, skills_dirs)
    if not items:
        print("No agent/skill markdown files found. Check config paths.")
        return 2

    decisions: Dict[str, Decision] = {}
    for it in items:
        decisions[str(it.path.resolve())] = decide(it)

    # report
    report_lines: List[str] = []
    report_lines.append("# Reclassify Report (Agents vs Skills)")
    report_lines.append("")
    report_lines.append(f"- repo: `{repo}`")
    report_lines.append(f"- mode: `{args.mode}`")
    report_lines.append(f"- generated: `{dt.datetime.utcnow().isoformat()}Z`")
    report_lines.append("")
    report_lines.append("| Item | Current | Recommended | Confidence | SkillScore | AgentScore | Rationale |")
    report_lines.append("|---|---:|---:|---:|---:|---:|---|")

    for it in sorted(items, key=lambda x: x.name.lower()):
        d = decisions[str(it.path.resolve())]
        rationale = ", ".join(d.rationale[:6])
        report_lines.append(
            f"| `{it.name}` | `{it.current_type}` | `{d.recommended}` | `{d.confidence:.2f}` | `{d.skill_score:.2f}` | `{d.agent_score:.2f}` | `{rationale}` |"
        )

    # plan + conversions
    conversions: List[Item] = []
    for it in items:
        d = decisions[str(it.path.resolve())]
        if d.confidence < convert_threshold and low_policy == "skip":
            continue
        if it.current_type != d.recommended:
            conversions.append(it)

    report_lines.append("")
    report_lines.append("## Plan summary")
    report_lines.append("")
    report_lines.append(f"- total items: {len(items)}")
    report_lines.append(f"- conversions (recommended != current): {len(conversions)}")
    report_lines.append(f"- low-confidence policy: `{low_policy}` (threshold: {convert_threshold}, low_conf: {low_conf_threshold})")
    report_lines.append("")

    write_text(repo / "reclassify-report.md", "\\n".join(report_lines) + "\\n")
    print("Wrote reclassify-report.md")

    if args.mode == "dry-run":
        print("Dry-run complete (no changes applied).")
        return 0

    # apply
    backup_root = repo / ".reclassify_backup" / now_stamp()
    backup_root.mkdir(parents=True, exist_ok=True)

    to_backup = [it.path for it in conversions] + [repo / "reclassify-report.md"]
    backup_paths(repo, backup_root, to_backup)
    print(f"Backup created at {backup_root}")

    rename_map: Dict[str, str] = {}

    for it in conversions:
        d = decisions[str(it.path.resolve())]
        low_conf = d.confidence < low_conf_threshold
        name = it.name

        if d.recommended == "skill":
            out_dir = repo / target_skills_dir / name
            out_file = out_dir / "SKILL.md"
            rendered = render_skill(name=name, original=it.text, low_conf=low_conf, embed_appendix=embed_appendix)
            write_text(out_file, rendered)
        else:
            out_file = repo / target_agents_dir / f"{name}.md"
            rendered = render_agent(name=name, original=it.text, low_conf=low_conf, embed_appendix=embed_appendix)
            write_text(out_file, rendered)

        rename_map[name] = name

    if update_refs and rename_map:
        modified = update_references(repo, scan_dirs, rename_map)
        print(f"Updated references in {len(modified)} markdown files." if modified else "No reference updates applied (no matches).")

    print("Apply complete. Review reclassify-report.md and then use git diff/status.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
