# Plannotator Demo Plan

## Context

You asked for a plan so you can test Plannotator. This file is the demo artifact — no real product work, just enough structure to exercise submit / annotate / deny / approve.

## Approach

Keep the plan tiny and self-contained. Use the existing `plans/` directory. Submit it for review so you can poke the UI.

## Files to modify

- None (demo only)
- Plan artifact: `plans/plannotator-demo.md`

## Reuse

- `plans/` convention already used by other plans in this repo
- `plannotator_submit_plan` for the review loop

## Steps

- [x] Create demo plan markdown under `plans/`
- [ ] Submit plan for review
- [ ] Open review UI and skim rendered markdown
- [ ] Optionally annotate a section
- [ ] Optionally deny with feedback and confirm resubmit works
- [ ] Approve when done testing

## Verification

| Check | Expected |
|-------|----------|
| Submit | Review UI opens with this plan |
| Render | Headings, checklist, table look right |
| Annotate | Notes stick to the plan (if supported) |
| Deny | Feedback returns to agent; plan can be edited in place |
| Approve | Planning phase completes |

## Notes

- Safe to approve or deny — nothing in the repo will change from this plan alone.
- If you deny, leave any feedback you want exercised (e.g. “add a joke section”) and the agent should revise this same file.
