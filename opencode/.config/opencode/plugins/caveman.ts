import type { Plugin, PluginOptions } from "@opencode-ai/plugin";

const LEVELS = [
  "lite",
  "full",
  "ultra",
  "wenyan-lite",
  "wenyan-full",
  "wenyan-ultra",
] as const;

type Level = (typeof LEVELS)[number];

type SessionMode = { kind: "enabled"; level: Level } | { kind: "disabled" };

type CavemanOptions = {
  enabled: boolean;
  level: Level;
};

const DEFAULT_OPTIONS: CavemanOptions = {
  enabled: true,
  level: "ultra",
};

const sessionModes = new Map<string, SessionMode>();

function isLevel(value: string): value is Level {
  return LEVELS.some((level) => level === value);
}

function parseOptions(options: PluginOptions | undefined): CavemanOptions {
  const enabled =
    typeof options?.enabled === "boolean"
      ? options.enabled
      : DEFAULT_OPTIONS.enabled;
  const level =
    typeof options?.level === "string" && isLevel(options.level)
      ? options.level
      : DEFAULT_OPTIONS.level;

  return { enabled, level };
}

function modeFor(sessionID: string, options: CavemanOptions): SessionMode {
  const sessionMode = sessionModes.get(sessionID);
  if (sessionMode) return sessionMode;
  return options.enabled
    ? { kind: "enabled", level: options.level }
    : { kind: "disabled" };
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

function parseCommand(
  argumentsText: string,
  options: CavemanOptions,
): SessionMode | "status" | undefined {
  const [raw] = argumentsText.trim().toLowerCase().split(/\s+/);
  if (!raw) return { kind: "enabled", level: options.level };
  if (raw === "status") return "status";
  if (raw === "off" || raw === "stop" || raw === "normal")
    return { kind: "disabled" };
  if (raw === "on") return { kind: "enabled", level: options.level };
  if (isLevel(raw)) return { kind: "enabled", level: raw };
  return undefined;
}

function modeLabel(mode: SessionMode): string {
  return mode.kind === "enabled" ? `enabled (${mode.level})` : "disabled";
}

function replaceCommandResponse(
  parts: { type: string; text?: string }[],
  message: string,
): void {
  for (const part of parts) {
    if (part.type === "text") {
      part.text = message;
      parts.splice(1);
      return;
    }
  }
}

export const CavemanPlugin: Plugin = async (_ctx, rawOptions) => {
  const options = parseOptions(rawOptions);

  return {
    "command.execute.before": async (input, output) => {
      if (input.command !== "caveman") return;

      const parsed = parseCommand(input.arguments, options);
      if (!parsed) {
        replaceCommandResponse(
          output.parts,
          `Unknown caveman level. Use: ${LEVELS.join(" | ")} | on | off | status.`,
        );
        return;
      }

      if (parsed === "status") {
        replaceCommandResponse(
          output.parts,
          `Caveman ${modeLabel(modeFor(input.sessionID, options))}.`,
        );
        return;
      }

      sessionModes.set(input.sessionID, parsed);
      replaceCommandResponse(output.parts, `Caveman ${modeLabel(parsed)}.`);
    },
    "experimental.chat.system.transform": async (input, output) => {
      const sessionID = input.sessionID;
      if (!sessionID) return;

      const mode = modeFor(sessionID, options);
      if (mode.kind === "disabled") return;

      output.system.push(instructions(mode.level));
    },
  };
};

export default CavemanPlugin;
