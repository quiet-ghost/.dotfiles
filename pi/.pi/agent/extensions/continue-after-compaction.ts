import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function continuationPrompt(
  sessionFile: string | undefined,
  compactionEntryId: string,
): string {
  const sessionSource = sessionFile
    ? `The persisted session JSONL is ${JSON.stringify(sessionFile)}. Inspect it directly; do not launch nested Pi.`
    : "This session is ephemeral, so no persisted session file is available.";

  return `Compaction has completed. Resume the existing task without waiting for another user prompt.

${sessionSource}
The compaction entry ID is ${JSON.stringify(compactionEntryId)}.

Recover the original goal, user constraints, decisions, changed files, verification already run, unresolved issues, and intended next action. Reconcile that history with the current worktree, briefly state the recovered context, then immediately perform the next unfinished step.`;
}

export default function continueAfterCompaction(pi: ExtensionAPI): void {
  const timers = new Set<ReturnType<typeof setTimeout>>();

  pi.on("session_compact", (event, ctx) => {
    const prompt = continuationPrompt(
      ctx.sessionManager.getSessionFile(),
      event.compactionEntry.id,
    );
    const timer = setTimeout(() => {
      timers.delete(timer);
      pi.sendUserMessage(prompt, { deliverAs: "followUp" });
    }, 0);
    timers.add(timer);
  });

  pi.on("session_shutdown", () => {
    for (const timer of timers) clearTimeout(timer);
    timers.clear();
  });
}
