#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Lokuma Design — Cloud Client

Just describe what you're building. Lokuma figures out the rest.

Usage:
  python design.py "<describe your product or design need>"
  python design.py "<describe your product or design need>" -p "Project Name"
  python design.py "<describe your product or design need>" -f json
  python design.py "<describe your product or design need>" -f markdown

Examples:
  python design.py "A meditation app for stressed professionals. Calm, premium, organic."
  python design.py "A landing page for an AI sales SaaS. Sharp, fast, conversion-focused." -p "Closer"
  python design.py "What color palette fits a luxury skincare brand?" -f json
  python design.py "Best font pairing for a fintech dashboard" -f markdown

Setup:
  export LOKUMA_API_KEY=lokuma_your_key_here
  Get your key at https://agent.lokuma.ai
"""

import argparse
import json
import os
import sys
import io
import urllib.request
import urllib.error
from typing import Optional

# Force UTF-8 output on Windows
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
if sys.stderr.encoding and sys.stderr.encoding.lower() != "utf-8":
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")


# ─────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────

API_BASE = os.environ.get("LOKUMA_API_URL", "https://api.lokuma.ai").rstrip("/")
API_VERSION = "v1"
_BASE = f"{API_BASE}/{API_VERSION}"


def _get_api_key() -> str:
    # 1. Try ~/.lokuma/config.json first
    config_path = os.path.expanduser("~/.lokuma/config.json")
    if os.path.exists(config_path):
        try:
            with open(config_path, "r") as f:
                config = json.loads(f.read())
                key = config.get("apiKey", "").strip()
                if key:
                    return key
        except Exception:
            pass

    # 2. Fallback to environment variable
    key = os.environ.get("LOKUMA_API_KEY", "").strip()
    if not key:
        print(
            "Error: LOKUMA_API_KEY is not set.\n"
            "Run:  lokuma auth login\n"
            "Or:   export LOKUMA_API_KEY=lokuma_your_key_here\n"
            "Get your key at https://agent.lokuma.ai",
            file=sys.stderr,
        )
        sys.exit(1)
    return key


# ─────────────────────────────────────────────
# HTTP client (stdlib only, zero deps)
# ─────────────────────────────────────────────

def _post(endpoint: str, payload: dict) -> dict:
    api_key = _get_api_key()
    url = f"{_BASE}/{endpoint}"
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "X-API-Key": api_key,
            "User-Agent": "lokuma-skill/2.0",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body)
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        try:
            err = json.loads(body)
            msg = err.get("error", body)
        except Exception:
            msg = body
        if e.code in (401, 403):
            print(f"Error: Invalid or expired API key (HTTP {e.code})", file=sys.stderr)
        elif e.code == 402:
            print(f"Error: {msg}", file=sys.stderr)
        else:
            print(f"Error: API returned HTTP {e.code}: {msg}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Error: Could not reach Lokuma API: {e.reason}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON response: {e}", file=sys.stderr)
        sys.exit(1)


# ─────────────────────────────────────────────
# Image reminder (appended to every recommendation)
# ─────────────────────────────────────────────

IMAGE_REMINDER = (
    "\n\n---\n"
    "> **Image requirement:** Always include real images when generating UI. "
    "Use high-quality placeholder sources such as Unsplash (`https://source.unsplash.com/...`) "
    "or Picsum (`https://picsum.photos/...`). "
    "Every hero section, card, and media slot must have an actual `<img>` tag or CSS background image. "
    "Do not leave image areas empty, use placeholder boxes, or skip images entirely."
)


# ─────────────────────────────────────────────
# Output formatting
# ─────────────────────────────────────────────

def _format_output(result: dict, fmt: str) -> str:
    if "error" in result:
        return f"Error: {result['error']}"

    # ── Print low-balance warning if present ──────────────────────────────────
    warning = result.get("warning")
    if warning:
        print(f"\n⚠️  {warning}\n", file=sys.stderr)

    # ── New /v1/design response: domains + recommendation ─────────────────────
    if "recommendation" in result:
        if fmt == "json":
            return json.dumps(result, indent=2, ensure_ascii=False)

        lines = []
        project = result.get("project_name")
        if project:
            lines.append(f"# {project}\n")

        # Per-domain matches summary
        domains = result.get("domains", {})
        if domains:
            lines.append("## Domain Matches\n")
            for domain, data in domains.items():
                match = data.get("match", {}) if isinstance(data, dict) else {}
                # pick a representative label from the match
                label = (
                    match.get("name") or match.get("Font Pairing Name") or
                    match.get("Pattern Name") or match.get("Product Type") or
                    match.get("Category") or match.get("family") or
                    next(iter(match.values()), "") if match else ""
                )
                lines.append(f"- **{domain}**: {label}")
            lines.append("")

        # Main recommendation
        lines.append(result["recommendation"])

        # Append image reminder
        lines.append(IMAGE_REMINDER)

        return "\n".join(lines)

    # ── Legacy: design-system response (has "output" key) ────────────────────
    if "output" in result:
        return result["output"] + IMAGE_REMINDER

    # ── Legacy: design-system json response ──────────────────────────────────
    if "design_system" in result:
        ds = result["design_system"]
        if fmt == "json":
            return json.dumps(ds, indent=2, ensure_ascii=False)
        lines = [f"## Design System: {ds.get('project_name', '')}\n"]
        for section, data in ds.items():
            if section == "project_name":
                continue
            lines.append(f"### {section.replace('_', ' ').title()}")
            if isinstance(data, dict):
                for k, v in data.items():
                    lines.append(f"- **{k}**: {v}")
            else:
                lines.append(str(data))
            lines.append("")
        return "\n".join(lines) + IMAGE_REMINDER

    # ── Legacy: multi-domain response ────────────────────────────────────────
    if result.get("strategy") == "multi":
        if fmt == "json":
            return json.dumps(result, indent=2, ensure_ascii=False)
        lines = ["## Lokuma Design Results\n"]
        for r in result.get("results", []):
            domain = r.get("domain", "")
            lines.append(f"### {domain.title()}")
            for i, row in enumerate(r.get("results", []), 1):
                lines.append(f"**{i}.** " + " | ".join(
                    f"{k}: {str(v)[:100]}" for k, v in list(row.items())[:4]
                ))
            lines.append("")
        return "\n".join(lines) + IMAGE_REMINDER

    # ── Legacy: single-domain response ───────────────────────────────────────
    if fmt == "json":
        return json.dumps(result, indent=2, ensure_ascii=False)

    lines = [f"## Lokuma — {result.get('domain', '').title()}\n"]
    lines.append(f"**Query:** {result.get('query', '')}\n")
    for i, row in enumerate(result.get("results", []), 1):
        lines.append(f"### Result {i}")
        for key, value in row.items():
            v = str(value)
            if len(v) > 300:
                v = v[:300] + "..."
            lines.append(f"- **{key}:** {v}")
        lines.append("")
    return "\n".join(lines) + IMAGE_REMINDER


# ─────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Lokuma Design Intelligence",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("query", help="Describe your product or design need in natural language")
    parser.add_argument("--project-name", "-p", type=str, default=None,
                        help="Optional project name")
    parser.add_argument("--format", "-f", choices=["ascii", "markdown", "json"],
                        default="ascii", help="Output format (default: ascii)")

    args = parser.parse_args()

    payload = {"query": args.query, "format": args.format}
    if args.project_name:
        payload["project_name"] = args.project_name

    result = _post("design", payload)
    print(_format_output(result, args.format))


if __name__ == "__main__":
    main()
