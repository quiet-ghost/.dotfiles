/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode-ai/plugin-v2/tui";

const LEVELS = [
  "lite",
  "full",
  "ultra",
  "wenyan-lite",
  "wenyan-full",
  "wenyan-ultra",
] as const;

type Level = (typeof LEVELS)[number];
type Mode = { kind: "enabled"; level: Level } | { kind: "disabled" };
type Modes = { sessions: Record<string, Mode> };

const DEFAULT_MODE: Mode = { kind: "enabled", level: "ultra" };
const OPTIONS = [
  { title: "full", value: "full", description: "Drop articles, fragments OK" },
  { title: "lite", value: "lite", description: "Tight professional sentences" },
  { title: "ultra", value: "ultra", description: "Maximum English compression" },
  { title: "wenyan-lite", value: "wenyan-lite", description: "Semi-classical Chinese" },
  { title: "wenyan-full", value: "wenyan-full", description: "Classical terse Chinese" },
  { title: "wenyan-ultra", value: "wenyan-ultra", description: "Extreme classical compression" },
  { title: "off", value: "off", description: "Normal response style" },
] as const;

function isLevel(value: string): value is Level {
  return LEVELS.some((level) => level === value);
}

function parseMode(input: string): Mode | "status" | undefined {
  const [raw] = input.trim().toLowerCase().split(/\s+/);
  if (!raw || raw === "on") return DEFAULT_MODE;
  if (raw === "status") return "status";
  if (raw === "off" || raw === "stop" || raw === "normal") return { kind: "disabled" };
  if (isLevel(raw)) return { kind: "enabled", level: raw };
}

function label(mode: Mode): string {
  return mode.kind === "enabled" ? mode.level : "off";
}

function instructions(level: Level): string {
  const levelRule: Record<Level, string> = {
    lite: "Intensity lite: no filler or hedging; keep articles and full professional sentences.",
    full: "Intensity full: drop articles, fragments OK, short synonyms preferred.",
    ultra: "Intensity ultra: abbreviate common technical terms, use arrows for cause/effect, one word when enough.",
    "wenyan-lite": "Intensity wenyan-lite: semi-classical Chinese register; drop filler but keep understandable grammar.",
    "wenyan-full": "Intensity wenyan-full: maximum classical Chinese terseness with classical particles where useful.",
    "wenyan-ultra": "Intensity wenyan-ultra: extreme terse classical Chinese feel while preserving technical meaning.",
  };

  return [
    "Caveman communication mode is active.",
    "Respond terse like smart caveman while keeping full technical accuracy.",
    "Drop pleasantries, filler, and hedging. Code blocks and quoted errors stay unchanged.",
    "Use pattern: [thing] [action] [reason]. [next step].",
    "Drop caveman style for security warnings, irreversible confirmations, or cases where terse fragments risk misunderstanding; resume after the clear part.",
    "Code, commit messages, and PR text stay normal unless user explicitly asks otherwise.",
    levelRule[level],
  ].join("\n");
}

export default Plugin.define({
  id: "caveman-tui",
  setup(ctx) {
    const [modes, updateModes] = ctx.storage.store<Modes>("modes", {
      initial: { sessions: {} },
    });

    const modeFor = (sessionID: string): Mode => modes.sessions[sessionID] ?? DEFAULT_MODE;

    const setMode = async (sessionID: string, mode: Mode): Promise<void> => {
      await ctx.client.session.instructions.entry.put({
        sessionID,
        key: "caveman",
        value: mode.kind === "enabled" ? instructions(mode.level) : "",
      });
      await updateModes((draft) => {
        draft.sessions[sessionID] = mode;
      });
      ctx.ui.toast.show({ message: `Caveman ${label(mode)}.`, variant: "info" });
    };

    const currentSessionID = (): string | undefined => {
      const route = ctx.ui.router.current();
      return route.type === "session" ? route.sessionID : undefined;
    };

    const selectMode = async (sessionID: string): Promise<void> => {
      const selected = await ctx.ui.dialog.select({
        title: "Caveman mode",
        current: label(modeFor(sessionID)),
        options: OPTIONS,
      });
      if (!selected) return;
      const mode = parseMode(selected);
      if (mode && mode !== "status") await setMode(sessionID, mode);
    };

    ctx.ui.slot({
      append: "prompt.footer.status",
      render(input) {
        ctx.keymap.layer(() => ({
          mode: "global",
          commands: [
            {
              id: "caveman.select",
              title: "Caveman mode",
              description: "Select the response compression level",
              group: "Prompt",
              bind: "<leader>v",
              palette: true,
              async run() {
                const sessionID = currentSessionID();
                if (!sessionID) {
                  ctx.ui.toast.show({
                    message: "Open a session before switching Caveman mode.",
                    variant: "warning",
                  });
                  return;
                }
                await selectMode(sessionID);
              },
            },
          ],
        }));

        if (!input.sessionID) return null;
        const mode = modeFor(input.sessionID);
        return (
          <text fg={ctx.theme.text.subdued}>
            caveman <span style={{ fg: mode.kind === "enabled" ? ctx.theme.text.feedback.warning.default : ctx.theme.text.subdued }}>{label(mode)}</span>
          </text>
        );
      },
    });
  },
});
