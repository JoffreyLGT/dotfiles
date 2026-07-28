# Workspace projects

Every project under `~/workspaces/` follows the same documentation layout. Create any missing pieces when working on a project; keep them up to date as part of the change, not as a follow-up.

## Required structure

```
<project>/
├── README.md
├── CHANGELOG.md
└── docs/
    ├── deployment.md
    ├── attachments/
    ├── specs/
    └── plans/
```

| Path | Audience | Content |
| --- | --- | --- |
| `README.md` | Anyone opening the repository | What the project does, and getting-started instructions for a new contributor. |
| `CHANGELOG.md` | Users and maintainers | Notable changes per release. See the changelog rules below. |
| `docs/deployment.md` | Engineers tasked with deploying | Everything needed to deploy and test the project, as ordered steps. |
| `docs/attachments/` | — | All screenshots and embedded documents referenced by the docs. Never inline binaries elsewhere. |
| `docs/specs/` | Agents and developers | Specifications for new development. A spec is the input to planning. |
| `docs/plans/` | Agents and developers | Implementation plans produced by agents, written before any code is changed. |

Plans are named `YYYYMMDDHHMM-short-description.md` (e.g. `202607281530-add-nedap-sync-retry.md`), so the directory stays in chronological order. Use the timestamp at which the plan is written.

## Way of working

Development follows spec → plan → implementation:

1. **Spec first.** A new development starts as a specification in `docs/specs/`. Do not begin implementing from a bare request — if no spec exists, ask whether to write one.
2. **Plan from the spec.** Read the relevant spec and write an implementation plan to `docs/plans/` before touching code. The plan is meant to be reviewed.
3. **Implement the plan.** Only then make the changes.

Keep `README.md` and `docs/deployment.md` accurate when a change affects how the project is set up, run, or deployed.

## Changelog

`CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project version follows [Semantic Versioning](https://semver.org/).

- Every user-facing change gets an entry under an `## [Unreleased]` section at the top. Add the entry in the same change that introduces it, not as a follow-up.
- Group entries under the standard headings, using only the ones that apply: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- Write entries for humans, not machines — describe the effect on the user, not the diff. Never paste commit logs.
- On release, rename `[Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` and open a fresh empty `[Unreleased]` above it. Keep releases in reverse-chronological order and maintain the link references at the bottom of the file.

```markdown
## [Unreleased]

### Added

- Retry with exponential backoff on Nedap sync failures.

### Fixed

- Deployment script no longer fails when `attachments/` is empty.
```

## Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `type(scope): description`.

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- The scope is optional and names the affected area, e.g. `feat(sync): ...`.
- The description is imperative and lower-case, with no trailing period: `fix(auth): handle expired refresh tokens`.
- Breaking changes are marked with `!` before the colon (`feat(api)!: ...`) and explained in a `BREAKING CHANGE:` footer.
- `feat` maps to a minor version bump, `fix` to a patch, and a breaking change to a major — keep this consistent with the changelog.

## Markdown style

Do not wrap lines in Markdown files. Write each paragraph as a single line and let the editor soft-wrap it. Only insert a newline where the structure requires one: between paragraphs, between list items, or around headings and code blocks. Never hard-wrap prose at a fixed column width — it makes diffs noisy, since editing one word reflows every following line in the paragraph.
