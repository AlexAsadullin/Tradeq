# User preferences

The user is Alex Asadullin (GitHub AlexAsadullin), a 2nd-year HSE student in AI, building Tradeq with
Arseny Demidanov. Writes to the assistant in English and Russian, often briefly; answer in the language of the
request.

## Workflow

- Do the work directly and sequentially. Subagents burn usage limits: at most one, only for a big
  self-contained piece. (On 2026-11-05 six parallel agents hit the 5-hour limit twice.)
- Keep each repo's README.md and .claude/HANDOVER.md true after changes, and keep this folder true.
- "Commit and push" means push to `main`; create missing remotes under AlexAsadullin.
- Be honest about evidence: say when a result is synthetic, a replay, or borderline. But the user wants clear
  verdicts: a hypothesis is "подтверждена" or "опровергнута", never "частично" or "на синтетике" as a status;
  split a partly confirmed claim into separate claims.
- Do not invent numbers. Every figure in a document must trace to a repo report; remove what cannot be traced.
- Security: do not trust the Russian CA; do not route orders to T-Bank; never expose the token.
- Check layout in a rendered preview before saying slides fit.

## Russian writing style (hackathon texts, research, slides)

The user's rules, applied to everything written in Russian for the hackathon:

- no participle or adverbial-participle phrases (причастные и деепричастные обороты);
- no sentences shorter than 10 words (headings and table cells excepted);
- prefer a comma over a colon, period or semicolon;
- no em dash, minimise dashes;
- strictly on topic; creative when the question is open;
- answers to numbered questions are numbered and have no trailing periods;
- respect character limits exactly (count them).

## Terminology

Use professional English terms instead of awkward Russian or transliterations: quant-трейдинг (not
"количественная торговля" or "квант"), overfitting, trials, fills, fill rate, backtest, baseline'ы, gateway,
gating, market making, market order, seeds, prompts, live, sandbox, edge, impact, latency. Keep normal Russian
words where they are standard: стакан, ордер, датасет, арена, алготрейдинг.
