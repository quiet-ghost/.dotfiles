import {
  isToolCallEventType,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

const gitEnvironment =
  "export GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true GIT_MERGE_AUTOEDIT=no\n";

export default function gitInterceptor(pi: ExtensionAPI): void {
  pi.on("tool_call", (event) => {
    if (!isToolCallEventType("bash", event)) return;
    if (!event.input.command.includes("git")) return;

    if (/--no-verify\b/.test(event.input.command)) {
      return {
        block: true,
        reason:
          "--no-verify is not allowed. Fix the hook failure or ask the user for help.",
      };
    }

    event.input.command = gitEnvironment + event.input.command;
  });
}
