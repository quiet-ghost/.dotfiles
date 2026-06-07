import type { Plugin } from "@opencode-ai/plugin";

const NOTES_DIR = "/home/ghost/personal/Notes/Imports";
const RELATIVE_NOTES_PREFIX = "home/ghost/personal/Notes/Imports";
const SECRETS_MIRROR_PREFIX =
  "/home/ghost/.local/share/opencode/secrets/home/ghost/personal/Notes/Imports";
const SECRETS_HOME_PREFIX = "/home/ghost/.local/share/opencode/secrets/home/";

function asRecord(value: unknown): Record<string, unknown> | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) return;
  return value as Record<string, unknown>;
}

function normalizeNotePath(filePath: string): string {
  if (filePath === RELATIVE_NOTES_PREFIX) return NOTES_DIR;
  if (filePath.startsWith(`${RELATIVE_NOTES_PREFIX}/`)) {
    return `/${filePath}`;
  }

  if (filePath === SECRETS_MIRROR_PREFIX) return NOTES_DIR;
  if (filePath.startsWith(`${SECRETS_MIRROR_PREFIX}/`)) {
    return `${NOTES_DIR}${filePath.slice(SECRETS_MIRROR_PREFIX.length)}`;
  }

  return filePath;
}

function blockSecretsMirror(filePath: string): void {
  if (filePath.startsWith(SECRETS_HOME_PREFIX)) {
    throw new Error(
      `Refusing to write under ${SECRETS_HOME_PREFIX}. Use the absolute notes directory ${NOTES_DIR}/ instead.`,
    );
  }
}

function normalizeFilePathArg(args: Record<string, unknown>): void {
  const filePath = args.filePath;
  if (typeof filePath !== "string") return;
  const normalized = normalizeNotePath(filePath);
  blockSecretsMirror(normalized);
  args.filePath = normalized;
}

function normalizePatchText(patchText: string): string {
  return patchText
    .split("\n")
    .map((line) => {
      const match = line.match(
        /^(\*\*\* (?:Add File|Update File|Delete File|Move to): )(.+)$/,
      );
      if (!match) return line;
      const prefix = match[1];
      const filePath = match[2];
      if (!prefix || !filePath) return line;
      const normalized = normalizeNotePath(filePath);
      blockSecretsMirror(normalized);
      return `${prefix}${normalized}`;
    })
    .join("\n");
}

export const NotesPathGuardPlugin: Plugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (!["write", "edit", "apply_patch"].includes(input.tool)) return;

      const args = asRecord(output.args);
      if (!args) return;

      if (input.tool === "write" || input.tool === "edit") {
        normalizeFilePathArg(args);
        return;
      }

      const patchText = args.patchText;
      if (typeof patchText !== "string") return;
      args.patchText = normalizePatchText(patchText);
    },
  };
};

export default NotesPathGuardPlugin;
