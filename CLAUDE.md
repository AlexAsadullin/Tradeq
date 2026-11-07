# Tradeq workspace

Before any work, read [docs/claude/README.md](docs/claude/README.md) and the files it lists. They hold the
long-term context of this workspace: the 11 project repositories and their ports, data and T-Bank access
rules, headline results, hackathon materials, the user's preferences and the decisions so far.

Hard rules (details in docs/claude):

- The T-Bank token is for market-data download only; never print or commit it; never send orders to T-Bank,
  not even its sandbox. Trading runs only in the local sandboxes (I9, I6) at 0.25% per fill, 0% for T-Capital
  funds.
- T-Bank is reached through SPKI key pinning; never install or trust the Russian Trusted Root CA.
- Each project folder is its own git repo with its own README.md and .claude/HANDOVER.md; keep them and
  docs/claude true after every change.
- Work sequentially in the main session; use subagents sparingly.
- Russian texts follow the style rules in docs/claude/user-preferences.md.
