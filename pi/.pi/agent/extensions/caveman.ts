import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  truncateToWidth,
  visibleWidth,
  type AutocompleteItem,
} from "@earendil-works/pi-tui";

const LEVELS = [
  "lite",
  "full",
  "ultra",
  "wenyan-lite",
  "wenyan-full",
  "wenyan-ultra",
] as const;

const DEFAULT_LEVEL: Level = "ultra";
const ENTRY_TYPE = "caveman-mode";
const INDICATOR_KEY = "caveman";

const SELECTOR_OPTIONS = [
  { value: "full", description: "Drop articles, fragments OK" },
  { value: "lite", description: "Tight professional sentences" },
  { value: "ultra", description: "Maximum English compression" },
  { value: "wenyan-lite", description: "Semi-classical Chinese" },
  { value: "wenyan-full", description: "Classical terse Chinese" },
  { value: "wenyan-ultra", description: "Extreme classical compression" },
  { value: "off", description: "Normal response style" },
] as const;

const COMPLETIONS: AutocompleteItem[] = [
  ...LEVELS.map((level) => ({ value: level, label: level })),
  { value: "on", label: "on" },
  { value: "off", label: "off" },
  { value: "status", label: "status" },
];

const USAGE = `Usage: /caveman [${LEVELS.join("|")}|on|off|status]`;

type Level = (typeof LEVELS)[number];
type Mode = { kind: "enabled"; level: Level } | { kind: "disabled" };
type ParsedCommand = Mode | "status" | "select" | undefined;

function isLevel(value: unknown): value is Level {
  return typeof value === "string" && LEVELS.some((level) => level === value);
}

function isMode(value: unknown): value is Mode {
  if (typeof value !== "object" || value === null || !("kind" in value)) return false;
  if (value.kind === "disabled") return true;
  return value.kind === "enabled" && "level" in value && isLevel(value.level);
}

function defaultMode(): Mode {
  return { kind: "enabled", level: DEFAULT_LEVEL };
}

function parseCommand(args: string): ParsedCommand {
  const input = args.trim().toLowerCase();
  if (!input) return "select";
  if (input === "status") return "status";
  if (input === "off" || input === "stop" || input === "normal") {
    return { kind: "disabled" };
  }
  if (input === "on") return defaultMode();
  if (isLevel(input)) return { kind: "enabled", level: input };
  return undefined;
}

function shortLabel(mode: Mode): string {
  return mode.kind === "enabled" ? mode.level : "off";
}

function modeLabel(mode: Mode): string {
  return mode.kind === "enabled" ? `enabled (${mode.level})` : "disabled";
}

function instructions(level: Level): string {
  const base = [
    "Caveman communication mode is active.",
    "Respond terse like smart caveman while keeping full technical accuracy.",
    "Drop pleasantries, filler, and hedging. Code blocks and quoted errors stay unchanged.",
    "Use pattern: [thing] [action] [reason]. [next step].",
    "Drop caveman style for security warnings, irreversible confirmations, or cases where terse fragments risk misunderstanding; resume after the clear part.",
    "Code, commit messages, and PR text stay normal unless user explicitly asks otherwise.",
  ];

  const levelRule: Record<Level, string> = {
    lite: "Intensity lite: no filler or hedging; keep articles and full professional sentences.",
    full: "Intensity full: drop articles, fragments OK, short synonyms preferred.",
    ultra:
      "Intensity ultra: abbreviate common technical terms, use arrows for cause/effect, one word when enough.",
    "wenyan-lite":
      "Intensity wenyan-lite: semi-classical Chinese register; drop filler but keep understandable grammar.",
    "wenyan-full":
      "Intensity wenyan-full: maximum classical Chinese terseness with classical particles where useful.",
    "wenyan-ultra":
      "Intensity wenyan-ultra: extreme terse classical Chinese feel while preserving technical meaning.",
  };

  return [...base, levelRule[level]].join("\n");
}

function paintIndicator(ctx: ExtensionContext, mode: Mode): void {
  ctx.ui.setWidget(
    INDICATOR_KEY,
    (_tui, theme) => ({
      render(width) {
        const color = mode.kind === "enabled" ? "warning" : "muted";
        const text = `caveman ${theme.fg(color, shortLabel(mode))}`;
        const content = truncateToWidth(text, width, "");
        return [`${" ".repeat(Math.max(0, width - visibleWidth(content)))}${content}`];
      },
      invalidate() {},
    }),
    { placement: "belowEditor" },
  );
}

function restoreMode(ctx: ExtensionContext): Mode {
  const entries = ctx.sessionManager.getEntries();
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index];
    if (entry?.type === "custom" && entry.customType === ENTRY_TYPE && isMode(entry.data)) {
      return entry.data;
    }
  }
  return defaultMode();
}

export default function caveman(pi: ExtensionAPI): void {
  let mode: Mode = defaultMode();

  const updateMode = (ctx: ExtensionContext, nextMode: Mode): void => {
    mode = nextMode;
    pi.appendEntry(ENTRY_TYPE, mode);
    paintIndicator(ctx, mode);
    ctx.ui.notify(`Caveman ${modeLabel(mode)}.`, "info");
  };

  const openSelector = async (ctx: ExtensionContext): Promise<void> => {
    if (!ctx.hasUI) {
      ctx.ui.notify(`${USAGE}; selector requires interactive mode.`, "warning");
      return;
    }

    const labels = SELECTOR_OPTIONS.map(
      (option) => `${option.value} — ${option.description}`,
    );
    const selected = await ctx.ui.select(
      `Caveman mode (current: ${shortLabel(mode)})`,
      labels,
    );
    if (!selected) return;

    const index = labels.indexOf(selected);
    const value = SELECTOR_OPTIONS[index]?.value;
    const parsed = value ? parseCommand(value) : undefined;
    if (parsed && parsed !== "status" && parsed !== "select") updateMode(ctx, parsed);
  };

  pi.on("session_start", (_event, ctx) => {
    mode = restoreMode(ctx);
    paintIndicator(ctx, mode);
  });

  pi.registerCommand("caveman", {
    description: "Select or set Caveman mode",
    getArgumentCompletions: (prefix) => {
      const normalized = prefix.trim().toLowerCase();
      const matches = COMPLETIONS.filter((item) => item.value.startsWith(normalized));
      return matches.length > 0 ? matches : null;
    },
    handler: async (args, ctx) => {
      const parsed = parseCommand(args);
      if (parsed === "select") {
        await openSelector(ctx);
        return;
      }
      if (parsed === "status") {
        ctx.ui.notify(`Caveman ${modeLabel(mode)}.`, "info");
        return;
      }
      if (!parsed) {
        ctx.ui.notify(USAGE, "warning");
        return;
      }
      updateMode(ctx, parsed);
    },
  });

  pi.on("before_agent_start", (event) => {
    if (mode.kind === "disabled") return;
    return {
      systemPrompt: `${event.systemPrompt}\n\n${instructions(mode.level)}`,
    };
  });

  pi.on("session_shutdown", (_event, ctx) => {
    ctx.ui.setWidget(INDICATOR_KEY, undefined);
  });
}
