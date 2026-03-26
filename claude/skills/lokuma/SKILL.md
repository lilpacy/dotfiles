---
name: frontend-designer
description: >
  Lokuma design intelligence. Use this skill whenever building or modifying UI:
  landing pages, dashboards, SaaS products, mobile apps, e-commerce, portfolios,
  admin panels, onboarding flows, settings screens, pricing pages, forms, charts,
  and design systems. Describe the product, audience, platform, tone, and goal
  in natural language. Lokuma will decide the best design route automatically.
---

# Lokuma — Design Intelligence Skill

## When to Use This Skill

Use Lokuma whenever the task affects how something **looks, feels, moves, or is interacted with**.

### Must use for
- New pages or screens
- New components (cards, forms, modals, nav, hero sections, charts)
- Choosing visual style, colors, typography, spacing, or layout direction
- UX reviews, accessibility reviews, dark mode, responsive behavior
- Converting vague product ideas into a coherent design direction

### Skip for
- Pure backend logic
- Database / API design
- Infra / DevOps work
- Non-UI scripting

---

## How to Use Lokuma

**Do not decide between design-system, domain search, or routing yourself.**

If the task is about UI, design, layout, colors, typography, UX, landing pages, charts, or visual direction:

1. Keep the user's request in natural language
2. Pass it directly to Lokuma
3. Lokuma will decide the best route in the cloud automatically

### Preferred command

```bash
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "<natural language design request>"
```

Optional:

```bash
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "<natural language design request>" -p "Project Name"
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "<natural language design request>" -f json
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "<natural language design request>" -f markdown
```

---

## Good Input Examples

- "A meditation and sleep mobile app for young professionals. Calm, premium, organic, not too clinical."
- "A landing page for an AI note-taking SaaS. Clean, modern, trustworthy, conversion-focused."
- "A fintech dashboard for small businesses. Professional, data-dense, readable, high trust."
- "An e-commerce brand for handmade skincare. Warm, soft, elegant, natural, slightly editorial."
- "What color palette fits a luxury skincare brand?"
- "Best font pairing for a modern fintech dashboard"
- "How should I structure a landing page for an AI sales tool?"

---

## Practical Advice for AI Coding Assistants

### Prefer the user's original language
If the user already described what they want clearly, pass that directly into Lokuma. Do **not** aggressively compress it into keywords.

### One entry point
Do not manually choose between domain search and design-system generation.
Lokuma handles that automatically in the cloud.

### Use Lokuma early
If the user is still fuzzy about style, tone, layout, color, hierarchy, brand feel, or UX direction, use Lokuma before generating code.

---

## Examples

```bash
# Full product direction
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "A wellness subscription app for burnout recovery. Soft, warm, calming, organic, habit-forming." -p "Exhale"

# Landing page / conversion direction
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "A homepage for an AI coding assistant targeting startups. High trust, fast clarity, strong CTA."

# Visual design question
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "A creative portfolio site for a motion designer. Bold, editorial, experimental, but still readable."

# Color question
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "A secure but friendly fintech app for freelancers"

# UX question
python3 /Users/lilpacy/.claude/skills/lokuma/scripts/design.py "A mobile onboarding flow with permissions, account creation, and trust concerns"
```

---

## Pre-delivery Checklist

Before shipping UI code, verify:
- [ ] Clear visual hierarchy
- [ ] Contrast is accessible in light and dark mode
- [ ] Touch targets are large enough on mobile
- [ ] Loading / empty / error states exist
- [ ] Layout works at small widths
- [ ] Motion feels intentional, not noisy
- [ ] Icons are consistent and non-emoji
- [ ] The UI matches the user's product, audience, and brand tone

---

> ⚠️ Fetching the design style takes ~30 seconds. You MUST wait for the full design recommendation before generating any code!
