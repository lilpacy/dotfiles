#!/usr/bin/env python3
import sys
from pathlib import Path

try:
  import yaml  # PyYAML
except ImportError:
  print("PyYAML is required: pip install pyyaml", file=sys.stderr)
  sys.exit(1)

def md_table(headers, rows):
  out = []
  out.append("| " + " | ".join(headers) + " |")
  out.append("| " + " | ".join(["---"] * len(headers)) + " |")
  for r in rows:
    out.append("| " + " | ".join(r) + " |")
  return "\n".join(out)

def main(plot_path: Path):
  data = yaml.safe_load(plot_path.read_text(encoding="utf-8"))

  # Foreshadow ledger view
  f_rows = []
  for f in data.get("foreshadows", []) or []:
    f_rows.append([
      f.get("id",""),
      f.get("type",""),
      f.get("plant",{}).get("chapter_id","") + "/" + f.get("plant",{}).get("scene_id",""),
      f.get("payoff",{}).get("chapter_id","") + "/" + f.get("payoff",{}).get("scene_id",""),
      f.get("payoff",{}).get("proof",""),
    ])

  views_dir = plot_path.parent / "views"
  views_dir.mkdir(exist_ok=True)

  long_md = []
  long_md.append("# Long-term Views\n")
  long_md.append("## Foreshadow Ledger\n")
  long_md.append(md_table(
    ["ID","Type","Plant (CH/SC)","Payoff (CH/SC)","Proof"],
    f_rows or [["(none)","","","",""]]
  ))
  (views_dir / "long_term.md").write_text("\n".join(long_md), encoding="utf-8")
  print(f"Wrote: {views_dir / 'long_term.md'}")

if __name__ == "__main__":
  if len(sys.argv) != 2:
    print("Usage: render_tables.py plots/<slug>/plot.yml", file=sys.stderr)
    sys.exit(1)
  main(Path(sys.argv[1]))
