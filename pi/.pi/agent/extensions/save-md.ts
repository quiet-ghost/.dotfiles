import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function textContent(content: unknown): string {
  if (!Array.isArray(content)) return "";
  return content
    .filter(
      (part): part is { type: "text"; text: string } =>
        typeof part === "object" &&
        part !== null &&
        "type" in part &&
        part.type === "text" &&
        "text" in part &&
        typeof part.text === "string",
    )
    .map((part) => part.text)
    .join("\n\n");
}

export default function saveMarkdown(pi: ExtensionAPI): void {
  pi.registerCommand("save-md", {
    description: "Save the latest assistant response as Markdown",
    handler: async (args, ctx) => {
      await ctx.waitForIdle();
      const name = args.trim();
      if (!name) {
        ctx.ui.notify("Usage: /save-md name", "warning");
        return;
      }

      const branch = ctx.sessionManager.getBranch();
      let markdown = "";
      for (let index = branch.length - 1; index >= 0; index--) {
        const entry = branch[index];
        if (entry?.type !== "message" || entry.message.role !== "assistant") continue;
        markdown = textContent(entry.message.content);
        if (markdown.trim()) break;
      }
      if (!markdown.trim()) {
        ctx.ui.notify("No assistant response to save", "warning");
        return;
      }

      const fileName = name.endsWith(".md") ? name : `${name}.md`;
      const path = resolve(ctx.cwd, fileName);
      try {
        await writeFile(path, markdown.endsWith("\n") ? markdown : `${markdown}\n`, {
          encoding: "utf8",
          flag: "wx",
        });
        ctx.ui.notify(`Saved Markdown to ${path}`, "info");
      } catch (error: unknown) {
        if (
          typeof error === "object" &&
          error !== null &&
          "code" in error &&
          error.code === "EEXIST"
        ) {
          ctx.ui.notify(`File already exists: ${path}`, "error");
          return;
        }
        throw error;
      }
    },
  });
}
