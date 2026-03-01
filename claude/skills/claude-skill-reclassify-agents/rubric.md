# Rubric: Skill vs Subagent

## Skill (procedure-oriented)
Choose **Skill** when the knowledge is:
- reproducible: same input → same workflow → predictable output
- structured: templates, linting, transformations, generators
- tool-oriented: file ops, formatting, packaging, scaffolding
- guardrail-able: you can encode failure modes as steps/checks

Signals in content:
- "Steps", "Procedure", "Checklist", "Output format", "Template", "Do X then Y"
- strict schema (YAML/JSON), linters, converters, generators

## Subagent (role/decision-oriented)
Choose **Subagent** when the knowledge is:
- judgment-heavy: tradeoffs, prioritization, critiques
- exploratory: find gaps, propose options, evaluate alternatives
- persona-fixed: "security reviewer", "architect", "editor", "PM"

Signals in content:
- "Role", "Principles", "How I think", "What to look for"
- open-ended evaluation, scoring, debate, alternative generation

## Ambiguous (best pattern)
Split into **Skill + Subagent**:
- Skill: deterministic checks + reporting + formatting
- Subagent: interpretation, prioritization, recommendations
