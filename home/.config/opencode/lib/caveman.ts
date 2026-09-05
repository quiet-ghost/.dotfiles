import { Rpc } from "@opencode-ai/plugin/rpc";
import { z } from "zod";

const levels = [
  "lite",
  "full",
  "ultra",
  "wenyan-lite",
  "wenyan-full",
  "wenyan-ultra",
] as const;
const Mode = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("enabled"), level: z.enum(levels) }),
  z.object({ kind: z.literal("disabled") }),
]);
export type CavemanMode = z.infer<typeof Mode>;
const initial: CavemanMode = { kind: "enabled", level: "ultra" };
const sessionID = z.string().regex(/^ses/);

export const CavemanRpc = Rpc.define({
  id: "dotfiles.caveman",
  events: {},
  methods: {
    get: { input: z.object({ sessionID }), output: Mode },
    set: { input: z.object({ sessionID, mode: Mode }), output: Mode },
  },
});

function parse(input: string): CavemanMode | "status" | undefined {
  const value = input.trim().toLowerCase();
  if (value === "status") return "status";
  if (["off", "stop", "normal"].includes(value)) return { kind: "disabled" };
  if (!value || value === "on") return initial;
  const level = z.enum(levels).safeParse(value);
  return level.success ? { kind: "enabled", level: level.data } : undefined;
}

function instructions(mode: CavemanMode): string {
  if (mode.kind === "disabled") return "";
  const rules: Record<(typeof levels)[number], string> = {
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
  return [
    "Caveman communication mode is active.",
    "Respond terse like smart caveman while keeping full technical accuracy.",
    "Drop pleasantries, filler, and hedging. Code blocks and quoted errors stay unchanged.",
    "Use pattern: [thing] [action] [reason]. [next step].",
    "Drop caveman style for security warnings, irreversible confirmations, or cases where terse fragments risk misunderstanding; resume after the clear part.",
    "Code, commit messages, and PR text stay normal unless user explicitly asks otherwise.",
    rules[mode.level],
  ].join("\n");
}

export const Caveman = {
  Mode,
  levels,
  initial,
  parse,
  instructions,
  label: (mode: CavemanMode) => (mode.kind === "enabled" ? mode.level : "off"),
} as const;
