import { resolve } from "node:path";
import { z } from "zod";

const NOTES_DIR = "/home/ghost/personal/Notes/Imports";
const RELATIVE_NOTES = NOTES_DIR.slice(1);
const MIRROR_HOME = "/home/ghost/.local/share/opencode/secrets/home";
const MIRROR_NOTES = `${MIRROR_HOME}/ghost/personal/Notes/Imports`;
const Arguments = z.record(z.string(), z.unknown());

function notePath(value: string): string {
  let normalized = value;
  if (value === RELATIVE_NOTES || value.startsWith(`${RELATIVE_NOTES}/`)) {
    normalized = `/${value}`;
  } else if (value === MIRROR_NOTES || value.startsWith(`${MIRROR_NOTES}/`)) {
    normalized = `${NOTES_DIR}${value.slice(MIRROR_NOTES.length)}`;
  }
  const absolute = resolve(normalized);
  if (absolute === MIRROR_HOME || absolute.startsWith(`${MIRROR_HOME}/`)) {
    throw new Error(
      `Refusing to write to the secrets mirror. Use ${NOTES_DIR}/ instead. No file was changed.`,
    );
  }
  return normalized;
}

function prepare(tool: string, input: unknown): unknown {
  if (!["read", "write", "edit", "patch", "apply_patch"].includes(tool))
    return input;
  const parsed = Arguments.safeParse(input);
  if (!parsed.success) return input; // OpenCode reports malformed tool input.
  const args = parsed.data;
  for (const key of ["path", "filePath"]) {
    const value = args[key];
    if (typeof value !== "string") continue;
    if (tool === "read") {
      if (value.includes(".env")) {
        throw new Error(
          "Reading .env files is blocked to protect credentials. Use a redacted example instead; the file was not read.",
        );
      }
    } else {
      args[key] = notePath(value);
    }
  }
  if (
    (tool === "patch" || tool === "apply_patch") &&
    typeof args.patchText === "string"
  ) {
    args.patchText = args.patchText
      .split("\n")
      .map((line) => {
        const match = line.match(
          /^(\*\*\* (?:Add File|Update File|Delete File|Move to): )(.+)$/,
        );
        const prefix = match?.[1];
        const file = match?.[2];
        return prefix && file ? `${prefix}${notePath(file)}` : line;
      })
      .join("\n");
  }
  return args;
}

export const FileProtection = { prepare } as const;
