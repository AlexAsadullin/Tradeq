---
id: STANDARDS
title: README and research report standards
applies_to: [S6, I1, I2, S1, S7, I5, S8, I9, S3, I6]
extends: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# README and research report standards

This file adds to section 8 of the conventions. Every repository ships two documents, and they have
different jobs. The README tells a developer what the project does, how to run it and what it guarantees. The
research report gives the evidence, as metrics from experiments in this repository, for why the project chose
its model, architecture or framework, and how it compares with the analogs in its specification section.

## 1. README (README.md)

The README is short and useful. It contains only what a developer needs to use or change the project:

1. The claim: one paragraph that says what problem the project solves and the measurable result it achieves.
2. Quickstart: the exact commands, from the venv setup to the demo.
3. Configuration: where settings live, the env prefix, and the variables that matter.
4. Architecture: the modules and the data flow, in a few sentences or one small diagram.
5. Contracts produced and consumed, with links to conventions section 6.
6. Key results: a table with three to six headline numbers, each with its confidence interval, plus a link to
   the report.
7. Limitations and roadmap.

Leave out marketing words ("powerful", "blazing fast", "state-of-the-art", "seamless", "robust" without a
number), badges, emoji, filler sentences and the restating of the specification. Leave out jargon that the
README does not define. When a sentence can be deleted without loss, delete it.

## 2. Research report (docs/report.md)

Every project needs a report, because every project makes choices that need evidence. For a model project
(S1, S3, S7), the choice is the model and its training. For a framework or infrastructure project (S6, I1, I2,
I5, I6, I8, I9), the choice is the method, the storage engine or the engine adapter. For S8, the choice is the
statistical evaluation protocol.

The report rests on experiments that the repository can reproduce. Add a target, `make report`, that runs the
experiments, writes the metric tables under `$TRADEQ_DATA_DIR/<repository>/reports/`, and regenerates the
numbers that the report cites. Use fixed seeds, and give every metric with its confidence interval or standard
error and the number of runs or samples behind it. Each report compares the chosen approach with at least two
alternatives: the analogs named in the specification section where they can be installed or reimplemented
fairly, plus simple baselines. When an analog cannot be run (it is paid, closed or needs data the project lacks),
the report says so and compares the documented behaviour instead, with the source named.

Write the report in these sections: Question, Data, Methods, Experiments and results, Comparison with analogs,
Decision, Limitations, References. Synthetic data is acceptable when real data is not available yet. In that
case, the report says so, describes the generating process, and does not present synthetic results as market
evidence.

## 3. Writing rules for the report

The report follows these rules. The README follows rules 3, 5, 10, 14 and 15, and it may use short numbered
steps and tables.

Rule 1. Every sentence has at least five words and two or more clauses, because connectors such as "therefore",
"because", "however" and "which" show how the ideas relate. A fragment such as "Next, market share" has no verb,
so it does not work.

Rule 2. The text contains no participle phrases, because they overload a sentence and hide the actor. Write
"The model that we trained on tape data" instead of "The model, trained on tape data". Write "We took the tape
data, and we estimated the spread from it" instead of "Using tape data, we estimated the spread".

Rule 3. The text uses only characters from a standard keyboard, so it has no plus-minus sign, multiplication
sign, arrows, curly quotes or em dashes. Write "7.2% with a margin of error of 1.2 percentage points" instead of
a plus-minus figure, and use colons and hyphens only when the sentence cannot work without them.

Rule 4. The report has no backticks and no bulleted lists, and it uses bold and italics rarely. A numbered list
is allowed only when the order matters; each item is then an ordinary paragraph that starts with its number,
without list indentation. Tables of metrics are allowed. When an idea fits into a connected paragraph, write
the paragraph.

Rule 5. Every claim rests on a fact, and the source appears next to the fact, in the form "as (source) shows,
(claim)". The sources are either the present project's experiments (name the table or the make target) or the
publications cited in the specification.

Rule 6. When a conclusion follows from a paper or a document, write "(source), section X states that ..., so we
can conclude that ...". Refer to this work as "the present study" or "the present project".

Rule 7. Describe each method through the data it uses and the operations it performs, because a method's name
does not explain how it works.

Rule 8. When a parameter changed during the study, name the parameter, its value before and after, and the
fact that caused the change.

Rule 9. Inanimate things do not speak or want; people and organisations act, and facts serve as evidence. Write
"the backtest results support the conclusion that ...", not "the backtest says ...".

Rule 10. Explain every technical term or abbreviation at its first mention, or replace it with plain words.
For example, at the first mention write "the deflated Sharpe ratio (DSR), which corrects the Sharpe ratio for the
number of strategies that the researcher tried".

Rule 11. Name every statistical test in full, and state its value, its critical value or p-value, and the
hypothesis. For example: "Student's t-test for two independent samples equals 2.70, while the critical value at
95% confidence is 2.31, so the difference in mean returns is not random."

Rule 12. Use every concept in its exact meaning, and do not stack redundant words.

Rule 13. Express uncertainty as a number: every average comes with its period or sample and its margin of
error.

Rule 14. The words "higher", "faster" and "better" always need a baseline, and the sentence gives both numbers.

Rule 15. Delete every phrase that can be removed without changing the meaning, such as "it should be noted",
"within the framework of", "plays a key role" or "as is well known".

Rule 16. A paragraph opens with its main conclusion, and the arguments follow it. Each object keeps one name
throughout the text.
