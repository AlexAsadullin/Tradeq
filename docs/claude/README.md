# Context for AI assistants

This folder is the long-term memory of the Tradeq workspace for Claude and other coding agents. A new session
should read it before doing anything, because the platform is large (11 repositories, a 644-line
specification, real market data, hackathon materials) and most decisions are not visible from the code alone.

Last full update: 2026-11-07.

## Read in this order

| File | What it holds |
|---|---|
| [project-overview.md](project-overview.md) | What Tradeq is, the 11 repositories, ports, status, how they connect |
| [conventions.md](conventions.md) | Engineering rules, layout, git rules, documentation rules for every repo |
| [data-and-tbank.md](data-and-tbank.md) | T-Invest token rules, key pinning, commissions, downloaded data, data root |
| [results.md](results.md) | Every headline number, where it comes from, and its caveats |
| [hackathon.md](hackathon.md) | T-Bank hackathon materials: answers, research docx, deck, PDF, how to rebuild |
| [user-preferences.md](user-preferences.md) | How the user wants work done: language, style rules, workflow, tone |
| [decisions-log.md](decisions-log.md) | Dated decisions and why they were made |
| [open-items.md](open-items.md) | What is not done, known gaps, next steps |

## Unmovable files

These paths are linked from the T-Bank hackathon application. Never move, rename or delete them:

- `quant_platform_plan_full.md` (the full specification; also the only plan file kept at the root)
- `docs/hackathon/architecture.md`
- `docs/hackathon/prototype.md`
- `docs/hackathon/calculation.md`
- `docs/hackathon/research.docx`
- `docs/hackathon/presentation.pdf`
- the repository itself, https://github.com/AlexAsadullin/Tradeq (keep it public, branch `main`)

## Plans

Finished plans are deleted; the unfinished parts live in [open-items.md](open-items.md). `PLAN-moex.md` (MOEX
pivot, 2026-10-29 to 2026-11-06) was fully done except the S4 RL agent and was removed on 2026-11-07.
`prompts/` holds the project briefs, which are specifications rather than plans, and stays in place.

## Rules for keeping this memory

- Update these files in the same commit as any change that makes them wrong (a new result, a new repo, a
  changed rule). Stale memory is worse than none.
- Facts only. Write numbers with their source file, sample and whether the data is synthetic or real.
- Never write secrets here. The T-Bank token lives only in two gitignored `.env` files.
- Each project repository also keeps its own `README.md` (public description) and `.claude/HANDOVER.md`
  (current state for the next session). This folder covers the whole workspace; per-repo detail stays there.
