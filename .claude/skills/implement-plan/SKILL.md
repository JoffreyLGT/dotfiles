---
name: implement-plan
description: Implement the latest plan from docs/plans/ using the plan-implementer agent (Opus 4.8, 1M context, high effort), then loop clean-context simplify → review → fix agents until the review reports no severe findings. Use when the user asks to implement, execute, or build the (latest) plan.
---

# Implement Plan

Implement the most recent plan under `docs/plans/` via subagents, then polish it with a
simplify → review → fix loop until the review comes back with **zero severe findings**.

You are the orchestrator: do not implement, simplify, review, or fix anything yourself — every
one of those steps runs in a dedicated subagent with a clean context. Your job is to select the
plan, launch agents in the right order, carry structured results between them, and decide when
the loop stops. Run every agent with `run_in_background: false` — each step depends on the
previous one.

## Step 1 — Locate the latest plan

Find the plan file with the highest `YYYYMMDDHHMM` timestamp prefix:

```bash
ls docs/plans/*.md | sort | tail -1
```

If `docs/plans/` is missing or empty, stop and tell the user there is no plan to implement.
If the arguments name a specific plan file instead, use that one.

## Step 2 — Implement

Launch **one** `plan-implementer` agent (its definition pins Opus 4.8 with the 1M context window
at high effort — do not override its model). Prompt it with:
- the absolute path of the plan file, and the project root;
- an instruction to implement the plan fully and run its Testing section.

Relay its report to the user (deviations from the plan especially). If it reports it could not
finish or verification is red, surface that and stop — do not start the polish loop on a broken
tree.

## Step 3 — Polish loop (until no severe findings)

Repeat the following round, **at most 5 times**:

1. **Simplify** — launch a `code-simplifier` agent on the uncommitted working tree (tell it the
   plan path for context on intent).
2. **Review** — launch a `change-reviewer` agent on the uncommitted working tree. Parse the
   fenced JSON `findings` block at the end of its report.
3. **Exit check** — if there are **no findings with `"severity": "severe"`**, the loop is done.
   (Minor findings do not block; report them to the user at the end.)
4. **Fix** — otherwise, launch a `finding-fixer` agent, passing the severe findings verbatim
   (file, line, summary, failure_scenario). Minor findings may be included as optional extras,
   clearly marked. Then start the next round.

Rules:
- Never reuse an agent between rounds — every launch is a fresh context by design.
- If the reviewer's output has no parseable JSON block, re-launch the reviewer once; if it fails
  again, fall back to treating its prose findings as severe and continue.
- If the same severe finding survives two consecutive rounds, stop the loop and escalate it to
  the user instead of burning more rounds.
- If the 5-round cap is hit with severe findings remaining, stop and report them — do not loop
  forever.

## Step 4 — Report

Final message to the user: plan implemented (with deviations), how many polish rounds ran, what
each round changed, remaining minor findings (if any), and the final verification status
(build/format/tests). Do not commit or push unless the user asks.
