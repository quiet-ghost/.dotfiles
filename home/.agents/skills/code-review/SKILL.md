---
name: code-review
description: Standards-backed code review workflow. Use when the user asks to review a diff, PR, branch, staged changes, working tree, or specific files for bugs, regressions, architecture, tests, or TypeScript safety.
---

# Code Review

Run a standards-backed review. Review-only: do not edit files unless the user explicitly asks for fixes after the review.

## Principles

- Review changed behavior, contracts, seams, tests, and runtime effects.
- Every finding needs proof: path, line, value flow, reachable failure, missing contract, leaked value, or inadequate test seam.
- Prefer fewer stronger findings over exhaustive commentary.
- Do not include praise or generic summaries before findings.

## Workflow

1. Select target from user instruction. If absent, inspect VCS state according to local VCS rules and review changed working tree or branch diff. Ask only if target remains unclear.
   If a fixed point is supplied, resolve it and compare with the merge-base using `git diff <fixed-point>...HEAD` (or the repository's VCS equivalent). Record the fixed point and commit range.
2. Load `coding-standards/SKILL.md`, then relevant topic refs for changed concerns.
3. Read full modified files, not only diff hunks.
4. If a spec, issue, or acceptance criteria exists, check explicit conformance and scope creep separately from standards compliance.
5. Trace values through boundary -> parser -> domain/service -> adapter -> response.
6. Build candidate findings only when proof exists.
7. Try to disprove each finding by checking surrounding code and local convention.
8. Output findings ordered by severity.

## What To Check

- Unparsed boundary data or trusted decoded JSON/storage rows.
- Expected failures hidden in throws/rejections.
- Secret leakage through errors/logs/traces/snapshots.
- Accidental interfaces, pass-through wrappers, dependency bags, hidden globals.
- Missing cancellation, floating promises, unsafe retries, unbounded concurrency.
- Tests coupled to internals, module mocks/spies, or missing behavior coverage.
- `any`, non-null assertions, unsafe casts, mutable exported contracts.
- Cloudflare runtime-hop or binding leakage.
- Effect code bypassing Services/Layers, typed errors, Schema, or Effect tests.

Use this concise smell baseline as a heuristic, never an automatic violation: mysterious names, duplicated code, feature envy, data clumps, primitive obsession, repeated switches, shotgun surgery, divergent change, speculative generality, message chains, middle men, and refused bequests. Local documented standards override it, and tooling-enforced issues need no finding.

## Severity

- **Blocker**: likely correctness, safety, security, data-loss, runtime, idempotency, boundary, observability, or test-integrity issue.
- **Should Fix**: meaningful design, contract, maintainability, diagnosability, or verification issue before merge.
- **Simplification**: smaller/deeper/clearer design without behavior change.
- **Nit**: small low-risk local issue.
- **Question**: ambiguity where product, domain, or local intent decides.

## Output

Start with:

```md
Review target: <target>
Standards loaded: <topic files>
```

For each finding:

```md
### <Severity>: <short title>

- **Issue:** <defect or risk>
- **Where:** `<file>:<line>`
- **Category:** <standard/topic>
- **Proof:** <value flow, reachable state, reproduction, or missing evidence>
- **Why it matters:** <behavioral consequence>
- **Fix direction:** <specific correction shape>
```

If no findings, state that directly and list the standards areas checked.
