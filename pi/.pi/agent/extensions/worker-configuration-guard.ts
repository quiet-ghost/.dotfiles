import {
  isToolCallEventType,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

const protectedFile = "worker-configuration.d.ts";
const protectedPath = /(?:^|[^\w.-])worker-configuration\.d\.ts(?:$|[^\w.-])/;
const mutation =
  /(^|[^<=>-])>>?|\b(?:tee|touch|cp|mv|rm|install|truncate|dd|rsync|python|python3|node|deno|ruby|bun|sed|perl)\b/;

function isProtectedPath(path: unknown): boolean {
  return (
    typeof path === "string" &&
    path.replace(/^@/, "").replaceAll("\\", "/").split("/").at(-1) ===
      protectedFile
  );
}

export default function workerConfigurationGuard(pi: ExtensionAPI): void {
  pi.on("tool_call", (event, ctx) => {
    if (isToolCallEventType("write", event) || isToolCallEventType("edit", event)) {
      if (!isProtectedPath(event.input.path)) return;
    } else if (isToolCallEventType("bash", event)) {
      if (
        !protectedPath.test(event.input.command) ||
        !mutation.test(event.input.command) ||
        /^\s*(?:npx|bunx|pnpm exec|npm exec)?\s*wrangler\s+types\b/.test(
          event.input.command,
        )
      ) {
        return;
      }
    } else {
      return;
    }

    if (ctx.hasUI) {
      ctx.ui.notify(`Blocked manual change to ${protectedFile}; run wrangler types.`, "warning");
    }
    return {
      block: true,
      reason: `${protectedFile} is generated. Run wrangler types instead of editing it.`,
    };
  });
}
