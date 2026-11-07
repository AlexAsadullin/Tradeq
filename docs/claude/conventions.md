# Conventions

The full rules are in `prompts/00-platform-conventions.md`; that file wins on engineering rules. Summary:

## Layout and tooling

- Each project is its own git repo in `$ROOT/<repo>/`, src layout: `pyproject.toml`, `uv.lock` (committed),
  `Makefile`, `README.md`, `.env.example`, `.gitignore`, `config/settings.yaml`, `src/<package>/`, `tests/`,
  `docs/report.md`, `.claude/HANDOVER.md`.
- Standard targets in every repo: `make setup lint typecheck test reproduce` (plus `serve`, `report` where
  relevant). Tests run offline by default; integration tests are opt-in.
- Python 3.13 in a per-repo `.venv` created with `uv`. Overlapping packages pinned exactly to
  `constraints.txt`.
- No hardcoding: one pydantic-settings object per project; defaults in `config/settings.yaml`, overrides from
  env (`<PREFIX>_SECTION__KEY`), secrets only from env.
- One data root: `TRADEQ_DATA_DIR` (= `$ROOT/data`), each repo writes to `data/<repo>/`. Never commit data.

## Git

- Commit in small logical steps with imperative messages. Every commit ends with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (or the attribution the current session asks for).
- All 11 repos and the umbrella have GitHub remotes under AlexAsadullin and are pushed. The user works on
  `main` directly; hackathon materials are committed straight to `main` of the umbrella.
- The umbrella gitignores the project folders; never add them to the umbrella.
- Untracked `.DS_Store` files appear in research-terminal; do not commit them.

## Documentation rules (each repo)

- `README.md`: claim paragraph with the headline number, quickstart, architecture, contracts, key results
  table with intervals and sample sizes, limitations, roadmap. Standards in prompt 11.
- `.claude/HANDOVER.md`: the current state for the next session; keep it true and short after every change.
- `docs/report.md`: method and full tables; `make report` regenerates it.
- Umbrella `README.md`: repository index with links, the status table and how pieces connect.
- After any change: update the repo README and HANDOVER, the umbrella README row, the spec status table if
  the status changed, and the files in `docs/claude/`.

## Contracts

HTTP and file contracts between services are numbered in section 6 of the conventions (for example 6.2 tape
format, 6.4 orders, 6.8 broker adapter, market slice). Change a contract only in the conventions file first,
then in every producer and consumer.

## Markets and fees

- Default market: MOEX shares (board TQBR) and T-Capital funds (TQTF). Whole lots, tick size per security,
  daily price bands, auctions, halts, MOEX sessions (morning, main, evening, weekend).
- Commission: 0.25% of trade value per fill (T-Invest basic tariff); 0% for T-Capital funds. The zero-fee list
  is `$TRADEQ_DATA_DIR/market-tape-recorder/reference/tbank_zero_fee_funds.json`.
- Crypto code was kept as optional modules that are off by default (S3, I5, I9, S8).
