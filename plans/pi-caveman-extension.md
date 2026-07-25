# Pi Caveman Extension Plan

## Context

Pi does not currently have a Caveman extension in this config, but its extension API supports the same behavior as the existing OpenCode integration. Here, “launches” means Caveman mode defaults on and its instructions are injected into each model turn; Caveman is not a separate process.

The OpenCode implementation defaults to `ultra`, supports `lite`, `full`, `ultra`, three `wenyan-*` levels, and `off`, exposes a selector at `<leader>v`, and renders `caveman <mode>` beside the prompt. Pi already loads the shared `skills/caveman/SKILL.md`, but skill discovery alone does not guarantee that a selected mode remains active every turn or expose UI state.

## Approach

- Add a Pi-native, auto-discovered extension under the existing global extension directory.
- Keep one authoritative mode for the current Pi session, defaulting to `ultra`.
- Inject the matching Caveman instructions through `before_agent_start`, so every turn follows the selected mode without adding a visible chat message.
- Register `/caveman` as the sole control surface: no argument opens Pi’s built-in selector, while `/caveman <level>`, `/caveman on|off`, and `/caveman status` act directly.
- Render the current mode persistently in Pi’s footer with `ctx.ui.setStatus`, using theme warning/muted colors for on/off.
- Persist mode changes as Pi custom session entries and recover the latest valid entry on `session_start`, preserving state across resume/reload while keeping sessions independent.

## Files to modify

- `pi/.pi/agent/extensions/caveman.ts` — new auto-loaded extension containing mode state, prompt injection, command/selector, footer indicator, and session persistence.
- `pi/.pi/tsconfig.json` — no change expected; it already includes every `agent/extensions/**/*.ts` file.
- `pi/.pi/agent/settings.json` — no change expected; Pi auto-discovers direct TypeScript files in the global extensions directory, and its settings schema has no extension-specific Caveman field. The extension owns the `ultra` default and session state.

## Reuse

- `opencode/.config/opencode/plugins/caveman.ts` — reuse supported levels, command aliases, default behavior, labels, and compact per-level system instructions.
- `opencode/.config/opencode/plugins/caveman-tui.tsx` — reuse selector ordering/descriptions and active/off indicator semantics.
- `skills/caveman/SKILL.md` — source of the canonical style, intensity, auto-clarity, and boundary rules; avoid inventing a second behavior.
- Pi 0.82 extension APIs already used by `pi/.pi/agent/extensions/save-md.ts` (`registerCommand`) and `pi/.pi/agent/extensions/whimsical.ts` (event/UI hooks); use Pi’s documented `before_agent_start`, `appendEntry`, `ctx.ui.select`, and `ctx.ui.setStatus` APIs for the remaining behavior.

## Steps

- [x] Define validated `Level`/mode types, the `ultra` startup default, command parsing (`on`, `off`/`stop`/`normal`, `status`, and all levels), display labels, selector options, and level-specific prompt text based on the OpenCode plugin/shared skill.
- [x] On `session_start`, restore the latest valid Caveman custom entry when present, otherwise activate `ultra`, then paint the footer indicator.
- [x] Register `/caveman` with argument completions: no argument opens the native selector; a level or on/off alias updates the mode; `status` reports it; invalid input shows usage. Route selector and direct changes through one update function that appends session state, refreshes the indicator, and notifies without sending a model prompt.
- [x] Add a `before_agent_start` handler that appends the active level’s instructions to the chained system prompt and leaves the prompt unchanged when mode is off.
- [x] Clear extension-owned footer UI during session shutdown if needed by Pi’s lifecycle, with session startup rebuilding it after new/resume/fork/reload.

## Verification

- Run `npm run check` from `pi/.pi` to type-check the extension against Pi 0.82.
- Start Pi and verify the extension auto-loads, the configured default is active, and `caveman <level>` appears in the footer.
- Exercise bare `/caveman` (selector), `/caveman status`, each supported level, `on`, `off`, invalid input, and argument completion; verify command actions do not create user prompts/model turns.
- Submit prompts while enabled and off to confirm the system prompt is respectively augmented and untouched.
- Resume/reload the same session and confirm its mode returns; create a new session and confirm it gets the startup default.
- Verify non-interactive Pi still applies prompt behavior without relying on selector/footer APIs.
