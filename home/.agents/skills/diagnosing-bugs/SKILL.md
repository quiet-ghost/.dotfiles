---
name: diagnosing-bugs
description: Diagnose hard bugs and performance regressions with a tight feedback loop. Use when behavior is broken, failing, throwing, incorrect, or slow.
---

# Diagnosing Bugs

Build a tight, red-capable feedback loop before forming a detailed theory. Skip phases only when the bug is trivial and the shortcut is explicit.

## 1. Build the feedback loop

Try, roughly in order:

1. Failing test at the seam reaching the bug.
2. Curl or HTTP script against a dev server.
3. CLI fixture invocation compared with known-good output.
4. Headless browser script with DOM, console, or network assertions.
5. Captured trace, payload, or event replay.
6. Minimal throwaway harness.
7. Property or fuzz loop.
8. Automated bisection or differential old/new loop.
9. Human-in-the-loop script from `scripts/hitl-loop.template.sh`.

Tighten it: make it fast, deterministic, and specific to the user's symptom. A flaky bug needs a higher reproduction rate, not necessarily a clean reproduction.

If no loop can be built, state what was tried and request the smallest useful artifact or environment access. Do not spend the whole investigation inventing unsupported hypotheses.

## 2. Reproduce and minimise

Run the loop repeatedly and confirm it produces the user's exact failure. Capture the error, wrong output, or timing before changing code.

Remove inputs, callers, configuration, data, and steps one at a time. Keep only load-bearing elements; the result should become the regression test where a correct seam exists.

## 3. Hypothesise

Once the loop is red, write 3-5 ranked, falsifiable hypotheses. Use: "If X causes it, changing Y will make it disappear or changing Z will make it worse."

State the ranking briefly, then continue autonomously; user feedback can re-rank it but is not a required checkpoint. For trivial bugs, one obvious hypothesis is acceptable when the red loop already proves the path.

## 4. Instrument

Map every probe to one prediction and change one variable at a time. Prefer a debugger or REPL, then targeted boundary logs; never log everything and search it.

Tag temporary logs with a unique prefix such as `[DEBUG-a4f2]`. For performance regressions, measure a baseline and bisect or profile instead of adding broad logs.

## 5. Fix and regress

Write the regression test before the fix when the test can exercise the real bug pattern through a public interface or correct production seam. A shallow test that cannot reproduce the call chain gives false confidence; record the missing seam instead.

Apply the smallest fix, watch the regression test pass, and rerun the original un-minimised loop. Verify the fix addresses the symptom, not only a nearby failure.

## 6. Clean up

- Rerun the original loop.
- Run the regression test and relevant focused checks.
- Use the dedicated Grep tool to find and remove every `[DEBUG-...]` log.
- Delete throwaway prototypes or clearly isolate intentional debug artifacts.
- Record the confirmed cause and prevention opportunity.

If the fix exposes a structural problem such as missing seams or hidden coupling, use the `improve-codebase-architecture` skill after the fix, with concrete evidence.
