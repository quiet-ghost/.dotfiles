import { Plugin } from "@opencode-ai/plugin";
import { Caveman, CavemanRpc, type CavemanMode } from "../lib/caveman";

export default Plugin.define({
  id: "caveman",
  async setup(ctx) {
    async function modeFor(sessionID: string): Promise<CavemanMode> {
      const stored = await ctx.storage.get(`session/${sessionID}`);
      return stored === undefined
        ? Caveman.initial
        : Caveman.Mode.parse(stored);
    }
    async function setMode(
      sessionID: string,
      mode: CavemanMode,
    ): Promise<CavemanMode> {
      await ctx.storage.set(`session/${sessionID}`, mode);
      return mode;
    }
    await ctx.rpc.register(CavemanRpc, {
      get: ({ sessionID }) => modeFor(sessionID),
      set: ({ sessionID, mode }) => setMode(sessionID, mode),
    });
    await ctx.session.hook("context", async (event) => {
      const text = Caveman.instructions(await modeFor(event.sessionID));
      if (text) event.system.push({ type: "text", text });
    });
    await ctx.command.transform((editor) => {
      editor.add({
        name: "caveman",
        description:
          "Set Caveman mode: lite, full, ultra, wenyan-*, on, off, status",
        async execute({ sessionID, prompt, delivery }) {
          const parsed = Caveman.parse(prompt.text ?? "");
          const mode =
            parsed && parsed !== "status"
              ? await setMode(sessionID, parsed)
              : await modeFor(sessionID);
          await ctx.session.prompt({
            sessionID,
            delivery,
            text: parsed
              ? `Caveman mode: ${Caveman.label(mode)}. Acknowledge briefly.`
              : `Unknown Caveman mode. Valid values: ${Caveman.levels.join(", ")}, on, off, status.`,
          });
        },
      });
    });
  },
});
