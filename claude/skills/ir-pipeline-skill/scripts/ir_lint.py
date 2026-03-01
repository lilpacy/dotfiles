#!/usr/bin/env python3
"""ir_lint.py — Lint PaperIR/TechIR/DocumentaryIR YAML/JSON.

Usage:
  python tools/ir_lint.py path/to/ir.yaml
  cat ir.yaml | python tools/ir_lint.py -

Notes:
- Prefers PyYAML if available.
"""

from __future__ import annotations
import sys, json, re
from typing import Any, Dict, List, Tuple

def eprint(*a: Any) -> None:
    print(*a, file=sys.stderr)

def load_doc(path: str) -> Dict[str, Any]:
    raw = sys.stdin.read() if path == "-" else open(path, "r", encoding="utf-8").read()
    try:
        import yaml  # type: ignore
        return yaml.safe_load(raw)
    except Exception:
        try:
            return json.loads(raw)
        except Exception as ex:
            eprint("Failed to parse as YAML/JSON. Install PyYAML: pip install pyyaml")
            raise ex

def norm_text(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r"\s+", " ", s)
    return s

def is_placeholder_id(s: str) -> bool:
    return isinstance(s, str) and ("?" in s)

def collect_ids(doc: Any) -> Dict[str, List[str]]:
    out: Dict[str, List[str]] = {}
    def walk(x: Any, path: str) -> None:
        if isinstance(x, dict):
            if "id" in x and isinstance(x["id"], str):
                out.setdefault(x["id"], []).append(path + ".id")
            for k, v in x.items():
                walk(v, f"{path}.{k}")
        elif isinstance(x, list):
            for i, v in enumerate(x):
                walk(v, f"{path}[{i}]")
    walk(doc, "$")
    return out

def anchors_for_obj(obj: Any) -> List[str]:
    if isinstance(obj, dict) and isinstance(obj.get("anchors"), list):
        return [a for a in obj["anchors"] if isinstance(a, str)]
    return []

def iter_objects_with_anchors(doc: Any) -> List[Tuple[str, str, List[str]]]:
    out: List[Tuple[str, str, List[str]]] = []
    def walk(x: Any, path: str) -> None:
        if isinstance(x, dict):
            if "anchors" in x:
                _id = x.get("id") if isinstance(x.get("id"), str) else ""
                out.append((path, _id, anchors_for_obj(x)))
            for k, v in x.items():
                walk(v, f"{path}.{k}")
        elif isinstance(x, list):
            for i, v in enumerate(x):
                walk(v, f"{path}[{i}]")
    walk(doc, "$")
    return out

def find_edges(doc: Any) -> List[Tuple[str, Dict[str, Any]]]:
    edges: List[Tuple[str, Dict[str, Any]]] = []
    def walk(x: Any, path: str) -> None:
        if isinstance(x, dict):
            if "from" in x and "to" in x and isinstance(x.get("from"), str) and isinstance(x.get("to"), str):
                edges.append((path, x))
            for k, v in x.items():
                walk(v, f"{path}.{k}")
        elif isinstance(x, list):
            for i, v in enumerate(x):
                walk(v, f"{path}[{i}]")
    walk(doc, "$")
    return edges

def collect_anchors_kinds(doc: Any) -> List[str]:
    kinds: List[str] = []
    anchors = (((doc.get("core") or {}).get("anchors")) if isinstance(doc, dict) else None)
    if isinstance(anchors, list):
        for a in anchors:
            if isinstance(a, dict) and isinstance(a.get("kind"), str):
                kinds.append(a["kind"])
    return kinds

def extract_content_fields(doc: Dict[str, Any]) -> List[Tuple[str, str, str]]:
    fields = []
    def add(path: str, obj: Dict[str, Any], key: str) -> None:
        if isinstance(obj.get(key), str) and obj.get(key).strip():
            _id = obj.get("id") if isinstance(obj.get("id"), str) else ""
            fields.append((path + f".{key}", _id, obj[key]))
    def walk(x: Any, path: str) -> None:
        if isinstance(x, dict):
            for key in ("statement","summary","rationale","note"):
                if key in x:
                    add(path, x, key)
            for k, v in x.items():
                walk(v, f"{path}.{k}")
        elif isinstance(x, list):
            for i, v in enumerate(x):
                walk(v, f"{path}[{i}]")
    walk(doc, "$")
    return fields

EVAL_WORDS_JA = ["良い","悪い","正しい","間違い","残虐","悲惨","素晴らしい","ひどい","許せない","称賛","非難"]
EVAL_WORDS_EN = ["good","bad","right","wrong","terrible","great","awful","unjust","praiseworthy","blameworthy"]

def lint(doc: Dict[str, Any]) -> Dict[str, Any]:
    known = set(collect_ids(doc).keys())
    errors = []
    warns = []
    notes = []

    # Anchor missing (contenty paths)
    for path, _id, ans in iter_objects_with_anchors(doc):
        if ans == [] and any(seg in path for seg in (
            ".argument.nodes", ".evidence.items", ".uncertainty.notes",
            ".procedure_design.goals", ".procedure_design.decisions", ".procedure_design.tradeoffs",
            ".procedure_design.steps", ".procedure_design.pitfalls",
            ".exceptions.notes", ".events.items", ".interpretations.claims",
            ".evidence.sources",
        )):
            errors.append(("ANCHOR_MISSING", f"{path} (id={_id})",
                           "Add at least one anchor ID (A*) pointing to source paragraph."))

    # Broken refs in edges
    for path, edge in find_edges(doc):
        fr = edge.get("from"); to = edge.get("to")
        if isinstance(fr, str) and fr not in known and not is_placeholder_id(fr):
            errors.append(("REF_BROKEN", f"{path}.from={fr}", "Fix the referenced ID or create it."))
        if isinstance(to, str) and to not in known and not is_placeholder_id(to):
            errors.append(("REF_BROKEN", f"{path}.to={to}", "Fix the referenced ID or create it."))
        for a in anchors_for_obj(edge):
            if a not in known and not is_placeholder_id(a):
                errors.append(("REF_BROKEN", f"{path}.anchors includes {a}", "Add the anchor to core.anchors or fix reference."))

    # Anchor granularity mix
    kinds = collect_anchors_kinds(doc)
    uniq = sorted(set(kinds))
    if len(uniq) >= 2:
        warns.append(("ANCHOR_GRANULARITY_MIX", "core.anchors.kind", f"Mixed kinds: {uniq}. Prefer one primary kind."))

    # Duplication
    content = extract_content_fields(doc)
    by_norm = {}
    for path, _id, text in content:
        nt = norm_text(text)
        if len(nt) < 12:
            continue
        by_norm.setdefault(nt, []).append((path, _id))
    for nt, occ in by_norm.items():
        if len(occ) >= 2:
            locs = [o[0] for o in occ]
            ev = any(".evidence." in p for p in locs)
            cl = any(".argument." in p or ".procedure_design." in p or ".interpretations." in p for p in locs)
            code = "EVIDENCE_DUPLICATES_CONTENT" if (ev and cl) else "SOT_DUPLICATE"
            (warns if code == "EVIDENCE_DUPLICATES_CONTENT" else errors).append((code, " | ".join(locs[:3]), "Keep SoT in one place; link by IDs."))

    # Low cohesion heuristic
    conj_pat = re.compile(r"( and | or |,|;| または | および | ・ )")
    for path, _id, text in content:
        if any(k in path for k in (".statement", ".summary", ".rationale")):
            if len(conj_pat.findall(text)) >= 6 and len(text) >= 80:
                warns.append(("LOW_COHESION", f"{path} (id={_id})", "Split into multiple nodes/steps/claims and connect with edges."))

    # Documentary neutrality
    if doc.get("ir_version") == "documentaryir.v0":
        facets = doc.get("facets") or {}
        events = ((facets.get("events") or {}).get("items")) if isinstance(facets, dict) else None
        if isinstance(events, list):
            for i, ev in enumerate(events):
                if isinstance(ev, dict) and isinstance(ev.get("summary"), str):
                    s = ev["summary"]
                    if any(w in s for w in EVAL_WORDS_JA) or any(re.search(r"\b"+re.escape(w)+r"\b", s.lower()) for w in EVAL_WORDS_EN):
                        warns.append(("EVENT_NOT_NEUTRAL", f"facets.events.items[{i}] (id={ev.get('id','')})", "Move evaluations to interpretations; keep events neutral."))

    verdict = "PASS"
    if errors: verdict = "FAIL"
    elif warns: verdict = "WARN"
    return {"ir_type": doc.get("ir_version","unknown"), "verdict": verdict, "errors": errors, "warnings": warns, "notes": notes}

def render(rep: Dict[str, Any]) -> str:
    lines = []
    lines.append("## 0) Summary")
    lines.append(f"- IR type: {rep['ir_type']}")
    lines.append(f"- Verdict: {rep['verdict']}")
    lines.append(f"- Counts: Errors={len(rep['errors'])}, Warnings={len(rep['warnings'])}, Notes={len(rep['notes'])}")
    lines.append("")
    def sec(title, items):
        lines.append(f"## {title}")
        if not items:
            lines.append("- (none)\n")
            return
        for code, loc, fix in items:
            lines.append(f"- Code: {code}")
            lines.append(f"  - Location: {loc}")
            lines.append(f"  - Minimal fix: {fix}")
        lines.append("")
    sec("1) Errors (must fix)", rep["errors"])
    sec("2) Warnings (should fix)", rep["warnings"])
    lines.append("## 3) Notes / Suggestions")
    lines.append("- (none)\n")
    lines.append("## 4) Quick checklist")
    lines.append(f"- Orthogonality: {'Needs work' if any(c in ('DISCOURSE_CONTAINS_CONTENT','PLAN_CONTAINS_CONTENT') for c,_,_ in rep['warnings']+rep['errors']) else 'OK'}")
    lines.append(f"- Non-overlap (SoT): {'Needs work' if any(c in ('SOT_DUPLICATE','EVIDENCE_DUPLICATES_CONTENT') for c,_,_ in rep['warnings']+rep['errors']) else 'OK'}")
    lines.append(f"- Granularity+Cohesion: {'Needs work' if any(c in ('ANCHOR_GRANULARITY_MIX','LOW_COHESION') for c,_,_ in rep['warnings']+rep['errors']) else 'OK'}")
    return "\n".join(lines)

def main():
    if len(sys.argv) != 2:
        eprint("Usage: python tools/ir_lint.py <path-or->")
        sys.exit(2)
    doc = load_doc(sys.argv[1])
    if not isinstance(doc, dict):
        eprint("Top-level document must be a mapping/object.")
        sys.exit(2)
    rep = lint(doc)
    print(render(rep))

if __name__ == "__main__":
    main()
