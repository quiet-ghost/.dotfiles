import net from "node:net";
import { z } from "zod";

type State = "idle" | "working" | "blocked";
type SessionState = {
  status: "idle" | "running";
  pending: boolean;
  blocked: boolean;
  failed: boolean;
};

function state(sessions: readonly SessionState[]): State {
  if (sessions.some((session) => session.blocked)) return "blocked";
  if (
    sessions.some((session) => session.status === "running" || session.pending)
  )
    return "working";
  return sessions.some((session) => session.failed) ? "blocked" : "idle";
}

function report(
  socketPath: string,
  params: Record<string, string | number>,
  method:
    "pane.report_agent" | "pane.report_agent_session" = "pane.report_agent",
): Promise<void> {
  return new Promise((resolve, reject) => {
    let response = "";
    const socket = net.createConnection(socketPath, () => {
      socket.write(
        `${JSON.stringify({ id: `opencode2:${params.seq}`, method, params })}\n`,
      );
    });
    const finish = (error?: Error) => {
      socket.destroy();
      if (error) reject(error);
      else resolve();
    };
    socket.setTimeout(500, () =>
      finish(new Error("Herdr state reporting timed out.")),
    );
    socket.once("error", finish);
    socket.on("data", (chunk: Buffer) => {
      response += chunk.toString();
      if (response.length > 65536)
        return finish(
          new Error("Herdr returned an oversized acknowledgement."),
        );
      if (!response.includes("\n")) return;
      try {
        const envelope = z
          .object({
            error: z.unknown().optional(),
            result: z.unknown().optional(),
          })
          .parse(JSON.parse(response));
        if (envelope.error || !("result" in envelope))
          return finish(new Error("Herdr rejected the agent state report."));
        finish();
      } catch {
        finish(new Error("Herdr returned an invalid acknowledgement."));
      }
    });
    socket.once("end", () =>
      finish(
        new Error("Herdr closed the socket before acknowledging agent state."),
      ),
    );
  });
}

export const HerdrState = { state, report } as const;
