import { Plugin } from "@opencode-ai/plugin/tui";
import { HerdrState } from "../../lib/herdr-state";

// Pane identity belongs to the terminal client, never to the shared server.
export default Plugin.define({
  id: "herdr.opencode2",
  setup(ctx) {
    const socketPath = process.env.HERDR_SOCKET_PATH;
    const paneID = process.env.HERDR_PANE_ID;
    if (process.env.HERDR_ENV !== "1" || !socketPath || !paneID) return;
    let sequence = Date.now() * 1000;
    let lastReport = "";
    let reporting = false;
    let warned = false;
    const tick = async () => {
      if (reporting) return;
      const route = ctx.ui.router.current();
      if (route.type !== "session") {
        lastReport = "";
        return;
      }
      const root = ctx.data.session.root(route.sessionID);
      if (!ctx.data.session.get(root)) return;
      const family = new Set([root, ...ctx.data.session.family(root)]);
      const state = HerdrState.state(
        [...family].map((id) => ({
          status: ctx.data.session.status(id),
          pending: ctx.data.session.pending.list(id).length > 0,
          blocked:
            (ctx.data.session.permission.list(id)?.length ?? 0) > 0 ||
            (ctx.data.session.form.list(id)?.length ?? 0) > 0,
          failed: id === root && ctx.data.session.get(id)?.outcome === "failed",
        })),
      );
      const signature = `${root}:${state}`;
      if (signature === lastReport) return;
      reporting = true;
      try {
        if (!lastReport.startsWith(`${root}:`)) {
          await HerdrState.report(
            socketPath,
            {
              pane_id: paneID,
              source: "herdr:opencode",
              agent: "opencode",
              seq: ++sequence,
              agent_session_id: root,
              session_start_source: "select",
            },
            "pane.report_agent_session",
          );
        }
        await HerdrState.report(socketPath, {
          pane_id: paneID,
          source: "herdr:opencode",
          agent: "opencode",
          seq: ++sequence,
          agent_session_id: root,
          state,
        });
        lastReport = signature;
        warned = false;
      } catch {
        if (!warned)
          ctx.ui.toast.show({
            message:
              "Herdr agent status could not be updated. OpenCode is still running; check the Herdr server. Reporting will retry.",
            variant: "warning",
          });
        warned = true;
      } finally {
        reporting = false;
      }
    };
    const timer = setInterval(
      () =>
        void tick().catch(() => {
          if (!warned)
            ctx.ui.toast.show({
              message:
                "Herdr session state could not be read. Reporting will retry.",
              variant: "warning",
            });
          warned = true;
        }),
      500,
    );
    return () => clearInterval(timer);
  },
});
