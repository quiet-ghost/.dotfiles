/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode-ai/plugin/tui";
import { createResource } from "solid-js";
import { Caveman, CavemanRpc } from "../../lib/caveman";

export default Plugin.define({
  id: "caveman-tui",
  setup(ctx) {
    const rpc = ctx.client.rpc(CavemanRpc);
    const sessionID = () => {
      const route = ctx.ui.router.current();
      return route.type === "session" ? route.sessionID : undefined;
    };
    ctx.ui.slot({
      append: "prompt.footer.status",
      render() {
        const [mode, { refetch }] = createResource(sessionID, async (id) => {
          const response = await rpc.get(
            { sessionID: id },
            { location: ctx.location ?? ctx.data.location.default() },
          );
          return response;
        });
        ctx.keymap.layer(() => ({
          mode: "global",
          commands: [
            {
              id: "caveman.select",
              title: "Caveman mode",
              description: "Select the response compression level",
              group: "Prompt",
              bind: "<leader>v",
              palette: true,
              slash: { name: "caveman", arguments: true },
              async run(input) {
                const id = sessionID();
                if (!id) {
                  ctx.ui.toast.show({
                    message: "Open a session before switching Caveman mode.",
                    variant: "warning",
                  });
                  return;
                }
                try {
                  const choice =
                    input?.trim() ||
                    (await ctx.ui.dialog.select({
                      title: "Caveman mode",
                      options: [...Caveman.levels, "off"].map((value) => ({
                        title: value,
                        value,
                      })),
                    }));
                  if (!choice) return;
                  const parsed = Caveman.parse(choice);
                  if (!parsed) {
                    ctx.ui.toast.show({
                      message:
                        "Unknown mode. Use lite, full, ultra, wenyan-*, on, off, or status.",
                      variant: "warning",
                    });
                    return;
                  }
                  const options = {
                    location: ctx.location ?? ctx.data.location.default(),
                  };
                  const selected =
                    parsed === "status"
                      ? await rpc.get({ sessionID: id }, options)
                      : await rpc.set({ sessionID: id, mode: parsed }, options);
                  // Remove instructions written by the older TUI so they cannot override off.
                  if (parsed !== "status")
                    await ctx.client.session.instructions.entry.remove({
                      sessionID: id,
                      key: "caveman",
                    });
                  await refetch();
                  ctx.ui.toast.show({
                    message: `Caveman ${Caveman.label(selected)}.`,
                    variant: "info",
                  });
                } catch {
                  ctx.ui.toast.show({
                    message:
                      "Could not synchronize Caveman mode. Check that the server's caveman plugin is loaded, then retry.",
                    variant: "error",
                  });
                }
              },
            },
          ],
        }));
        return (
          <text fg={ctx.theme.text.subdued}>
            caveman{" "}
            {mode.error
              ? "unavailable"
              : mode()
                ? Caveman.label(mode() ?? Caveman.initial)
                : "loading"}
          </text>
        );
      },
    });
  },
});
