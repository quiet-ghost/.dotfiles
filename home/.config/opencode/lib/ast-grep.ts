import type { ToolEditor } from "@opencode-ai/plugin/promise/tool";
import { z } from "zod";

export function registerAstGrep(editor: ToolEditor, directory: string): void {
  editor.add({
    name: "ast-grep_search",
    description: `Search code using ast-grep's structural AST pattern matching.

Use for code patterns hard to match with regex (formatting-agnostic).

Metavariables:
- $VAR: matches single AST node
- $$$VAR: matches zero or more nodes

Examples:
- console.log($$$ARGS) - find all console.log calls
- useState($INIT) - find React useState
- async function $NAME($$$PARAMS) { $$$BODY } - find async functions`,

    input: z.object({
      pattern: z.string().describe("AST pattern to match"),
      path: z.string().optional().describe("Path to search (default: .)"),
      lang: z
        .enum([
          "typescript",
          "tsx",
          "javascript",
          "python",
          "rust",
          "go",
          "java",
          "c",
          "cpp",
          "csharp",
          "kotlin",
          "swift",
          "ruby",
          "lua",
          "elixir",
          "html",
          "css",
          "json",
          "yaml",
        ])
        .optional()
        .describe("Language (auto-detected if omitted)"),
      json: z.boolean().optional().describe("Output as JSON"),
    }),

    async execute(args) {
      const cmd = ["ast-grep", "--pattern", args.pattern];
      if (args.lang) cmd.push("--lang", args.lang);
      if (args.json) cmd.push("--json");
      cmd.push(args.path ?? ".");

      const result = await Bun.$`${cmd}`.cwd(directory).nothrow().quiet();
      if (result.exitCode !== 0 && result.stderr.toString().trim()) {
        throw new Error(`ast-grep search failed: ${result.stderr.toString()}`);
      }
      return { content: result.stdout.toString() || "No matches found." };
    },
  });

  editor.add({
    name: "ast-grep_rewrite",
    options: { permission: "edit" },
    description: `Transform code using ast-grep pattern matching.

Rewrites matched patterns with replacement. Uses same metavariables from search pattern.

Example: pattern="console.log($MSG)" rewrite="logger.info($MSG)"`,

    input: z.object({
      pattern: z.string().describe("AST pattern to match"),
      rewrite: z
        .string()
        .describe("Replacement pattern (use same metavariables)"),
      path: z.string().optional().describe("Path to transform (default: .)"),
      lang: z.string().optional().describe("Language hint"),
    }),

    async execute(args) {
      const cmd = [
        "ast-grep",
        "--pattern",
        args.pattern,
        "--rewrite",
        args.rewrite,
        "--update-all",
      ];
      if (args.lang) cmd.push("--lang", args.lang);
      cmd.push(args.path ?? ".");

      const result = await Bun.$`${cmd}`.cwd(directory).nothrow().quiet();
      if (result.exitCode !== 0 && result.stderr.toString().trim()) {
        throw new Error(`ast-grep rewrite failed: ${result.stderr.toString()}`);
      }
      return { content: result.stdout.toString() || "No changes needed." };
    },
  });
}
