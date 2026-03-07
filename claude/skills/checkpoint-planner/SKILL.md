---
name: checkpoint-planner
description: >
  Helps users plan tasks by breaking them into small checkpoints that fail early,
  rather than trying to create one perfect big plan. Guides users through surfacing
  unknowns, identifying risks, and writing plans down as markdown files they can
  check while working. Use this skill whenever the user says "plan this", "help me plan",
  "break this down", "checkpoint plan", "what should I do first", "make a plan",
  "planning", or asks for help organizing a task that feels overwhelming or complex.
  Also trigger when the user seems stuck on where to start, or mentions they keep
  forgetting important things during planning.
---

# Checkpoint Planner

## Why This Exists

Planning fails when too many things are held in your head at once, key unknowns are discovered too late, and the plan isn't checked early enough. The solution is not to make a perfect big plan. The solution is to make **smaller plans that fail earlier**.

The target is: **notice wrong plans earlier and more cheaply.**

## Core Principles

1. **Plan only the next checkpoint** - Never plan the whole project at once. Plan only the next meaningful milestone where you can verify you're on the right track.

2. **Surface unknowns before doing work** - The things you don't know are more dangerous than the things you do know. Unknowns discovered late are expensive. Unknowns discovered early are cheap.

3. **Plans must exist outside your head** - If the plan lives only in memory, it will drift, lose details, and miss things. Write it down in a file you can check while working.

4. **Make reversible steps** - Don't commit too early to a huge direction. Break work into chunks where you can still change course without wasting too much effort.

5. **Review at 10-20%, not at 90%** - Don't wait until the work is almost finished to check whether the plan was correct. Review when you're only a small fraction done, so the cost of changing direction is still low.

## Workflow

### Step 1: Capture the Three Essentials

Before anything else, ask the user for these three things. If they've already provided some in the conversation, extract what you can and ask only for what's missing.

- **Goal**: What are you trying to achieve? (One sentence. If you can't say it in one sentence, it's not clear enough yet.)
- **Unknowns**: What might make this fail? What do you not know yet? What assumptions are you making that you haven't verified?
- **First Proof**: What is the smallest thing that proves you're on the right path? This is the first checkpoint - the thing you should do before doing anything else.

These three things are the minimum. Do not skip them. Do not jump ahead to planning steps before these are answered. The reason is that without a clear goal, you plan the wrong thing; without surfacing unknowns, you discover them too late; without a first proof, you do too much work before validating direction.

### Step 2: Reality Check

Before writing the plan, challenge assumptions. Ask the user (or think through together):

- Are you solving the right problem, or a symptom of a different problem?
- Did you assume something without verifying it?
- What would make this whole direction wrong?
- Is there a simpler version of this that achieves 80% of the value?

This step exists because the most expensive planning mistake is solving the wrong problem. A few minutes of questioning here can save hours or days of wasted work.

### Step 3: Write the Checkpoint Plan

Write a markdown file to the project. Use the path `plans/checkpoint-<slug>.md` relative to the project root (create the `plans/` directory if needed). If the user specifies a different location, use that instead.

The plan file uses this template:

```markdown
# Checkpoint Plan: <title>

**Created**: <date>
**Status**: Active

## Goal
<one clear sentence>

## Constraints
<what limits or boundaries exist - time, budget, technical, organizational>

## What I Know
<facts, confirmed information, things already verified>

## What I Don't Know
<unknowns, assumptions, things that need verification>
<mark the most dangerous unknown with [CRITICAL]>

## First Proof (Checkpoint 1)
<the smallest thing that proves the direction is right>
<what does "passing" this checkpoint look like?>

## What Could Make This Plan Wrong
<risks, wrong assumptions, external factors>

## Review Point
<when to review - aim for 10-20% of estimated effort>
<what questions to ask at review time>
```

### Step 4: Extended Checklist (for non-trivial tasks)

For tasks that are clearly non-trivial (multi-day, multi-person, or involving systems you don't fully control), add these sections to the plan file:

```markdown
## Dependencies
<what must exist or happen before this work can proceed>
<external teams, APIs, approvals, data>

## Edge Cases
<scenarios that are easy to forget>
<error states, empty states, concurrent access, rollback>

## Checkpoints
| # | Checkpoint | Pass Criteria | Review? |
|---|-----------|--------------|---------|
| 1 | <first proof> | <what success looks like> | Yes |
| 2 | <next milestone> | <criteria> | |
| 3 | <next milestone> | <criteria> | Yes |

## Definition of Done
<what "finished" actually means - be specific>
<include: tested, reviewed, deployed, documented?>
```

### Step 5: Next Action

After writing the plan, tell the user:
1. What the first checkpoint is
2. What the single next action to take is
3. When they should stop and review

Do not present a long list of future steps. The whole point is to focus on what's next, not what's eventually.

## Important Behaviors

- **Ask, don't assume.** If the user gives a vague request, ask clarifying questions before writing a plan. Bad assumptions baked into a plan are worse than no plan at all.

- **Keep plans short.** A good checkpoint plan fits on one screen. If it's getting long, you're planning too far ahead. Split it.

- **Flag the scariest unknown.** Every plan should have at least one unknown marked as [CRITICAL]. If you can't find one, you probably haven't thought hard enough about what could go wrong.

- **One checkpoint at a time.** After the user completes a checkpoint, they can come back and plan the next one. Don't front-load all the checkpoints at creation time unless the user explicitly asks for a roadmap.

- **Plans are living documents.** When the user returns after completing a checkpoint, update the plan file - mark checkpoints as done, add new unknowns discovered, adjust the direction if needed.
