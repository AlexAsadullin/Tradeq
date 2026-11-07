# T-Bank hackathon materials

Team: Асадуллин Александр and Демиданов Арсений, НИУ ВШЭ, «Технологии искусственного и дополненного
интеллекта», 2nd year. Everything for the hackathon is in Russian, in `docs/hackathon/`.

## Files

| Material | Path | Link given in the application |
|---|---|---|
| Architecture diagram | `docs/hackathon/architecture.md` | https://github.com/AlexAsadullin/Tradeq/blob/main/docs/hackathon/architecture.md |
| Repository | umbrella | https://github.com/AlexAsadullin/Tradeq |
| Technical prototype | `docs/hackathon/prototype.md` (terminal screenshots in `img/`) | https://github.com/AlexAsadullin/Tradeq/blob/main/docs/hackathon/prototype.md |
| Calculation | `docs/hackathon/calculation.md` | https://github.com/AlexAsadullin/Tradeq/blob/main/docs/hackathon/calculation.md |
| Research | `docs/hackathon/research.docx` | https://github.com/AlexAsadullin/Tradeq/blob/main/docs/hackathon/research.docx |
| Presentation | `docs/hackathon/presentation.pdf` (11 slides) | https://github.com/AlexAsadullin/Tradeq/blob/main/docs/hackathon/presentation.pdf |
| Other material | spec | https://github.com/AlexAsadullin/Tradeq/blob/main/quant_platform_plan_full.md |

Index: `docs/hackathon/README.md`. Build sources and instructions: `docs/hackathon/src/README.md`.

## Application answers

The application form had numbered questions with character limits (900, 600, 1000, 700, 450, 1200, 700, 700,
800, 5000). Answers were written "as if the project is finished", strictly on topic, creative where the question
is open. The AI question was about trading strategies and the system's AI, not about AI writing code. Answers
are numbered and have no trailing periods. One 5000-character answer quoted "8%" (see results.md for its
setup). The answer texts themselves are not stored in the repo.

## Research document (`research.docx`)

About 6,700 words, Russian academic template: Введение (актуальность, 7 problems, объект и предмет, criterion,
цель, 7 tasks, hypotheses H0–H4, methods, novelty split into scientific and engineering, practical value,
structure), theoretical part with formulas, practical part (literature protocol, data, experiments 1–7 with
real N and intervals, costs, reproducibility, limitations), Заключение with a hypothesis table, 60 sources
(GOST-like with access dates, mostly English, plus Chinese and Russian), appendices А–Д. Automatic TOC, no
numbers in headings or sources, citations like [E1] are clickable. The project split into tracks to build an
independent AI-agent incubator is mentioned before the practical part. Module codes (S1, I5) are not used in
the text. It was revised after an expert critique (protocols, real sample sizes, replay vs real fills,
synthetic LLM test, breakeven 147 ticks).

## Presentation

- Editable master: claude.ai Slides artifact https://claude.ai/artifact/6JJr5TwdM6uLMWCuy6zwEj (private; share
  from its Share menu). The user edits it by hand in the editor; always re-read it before changing it.
- Copy of the slides: `docs/hackathon/src/deck/slides/*.html`; PDF via `python3 build_pdf.py` (Chrome headless).
- Template required by the organisers: 1 title; 2 relevance, problem, goal; 3 analogs table and approach;
  4 dataset, architecture, stack; 5–9 technical details of ML, RL, DL, AI; 10 plans; 11 demo with a QR code.
- Slides: cover (photos: Alexander left, Arseny right), goal, analogs (FinRL, Qlib, pypbo/qf-lib, T-Invest
  sandbox vs Tradeq), stack (architecture diagram), ML validation (DSR, N_eff, PBO; 43.7% vs 0.5%), ML execution
  (queue model, fill model, fidelity ladder), DL (TSFM arena, simulators G), RL (environment, rl/v1, agent
  "в работе", baselines TWAP and GLFT), AI (gateway, probe, arena), roadmap (5 steps + 5 confirmed hypotheses,
  aligned two-column cards), demo (QR to github.com/AlexAsadullin/Tradeq, no hosted demo exists).
- Design: 1920×1080; light background #F3F1EA, dark #10141F, cards #FFFFFF with border #DDD8CC and radius 16px,
  blue #3D7BFF, orange #F29A38, red #C0392B for bad numbers; Manrope headings, IBM Plex Sans body; slide number
  "N / 11" at bottom right; speaker notes in `<aside>`.
- Layout rules learned from the user: no small footers at the bottom (the user deleted them), fill empty space
  by centering and enlarging, keep blocks aligned, never break words (hyphenation off, hyphenated words in
  `white-space:nowrap`), statuses only "подтверждена" or "опровергнута", no H1/H2 labels on slides.
