---
name: write-plan
description: Create an implementation plan and save it to docs/plans/YYYYMMDDHHMM-description.md instead of only printing it to the terminal, so it can be reviewed and implemented later. Use when the user asks to plan a task, design an approach, or draft an implementation strategy for later review.
---

# Write Plan

Produce an implementation plan for the requested task and **persist it to a file** under
`docs/plans/` so the user can review it later and ask for the implementation in a separate step.
Do **not** implement anything now — planning only.

## Steps

1. **Understand the task.** Read the relevant code, docs, and configuration needed to plan well.
   Ask clarifying questions only if a decision genuinely blocks the plan (see the AskUserQuestion
   guidance); otherwise pick sensible defaults and note them in the plan.

2. **Compute the filename.** The plan lives at `docs/plans/YYYYMMDDHHMM-description.md`:
   - `YYYYMMDDHHMM` is the current local timestamp to the minute. Get it with a real command —
     never guess or reuse a date from context:
     ```
     date +%Y%m%d%H%M
     ```
     (Bash tool). On PowerShell: `Get-Date -Format 'yyyyMMddHHmm'`.
   - `description` is a short kebab-case slug summarizing the task (e.g. `add-retry-to-publisher`).
   - Create the `docs/plans/` directory if it does not exist.

3. **Write the plan file.** Use the Write tool. Structure the plan as markdown:
   - `# <Title>` — the task in one line.
   - **Context / Goal** — what we're doing and why.
   - **Assumptions & open questions** — defaults chosen, anything to confirm before implementing.
   - **Plan** — ordered, concrete steps. Reference specific files (`file_path:line`), functions,
     and the changes each step makes. Enough detail that implementation is mechanical.
   - **Testing** — how the change will be verified (tests to add/run).
   - **Risks / rollback** — what could break and how to back out.

4. **Report back.** Tell the user the plan path (e.g. `docs/plans/202607061530-add-retry.md`),
   give a 2-3 sentence summary, and remind them you have **not** implemented it — they can review
   the file and ask for the implementation whenever they're ready.

## Notes

- Keep the plan self-contained: someone (or a fresh session) should be able to implement it from
  the file alone.
- Follow the project's conventions (CLAUDE.md) in the plan — e.g. update docs/appsettings, no
  co-authored commits, run `dotnet format`/`dotnet test`.
- One plan per invocation; never overwrite an existing plan file — the timestamp keeps them unique.
