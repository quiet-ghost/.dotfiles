import { Plugin } from "@opencode/plugin";
import { FileProtection } from "../lib/file-protection";

export default Plugin.define({
  id: "file-protection",
  async setup(ctx) {
    await ctx.tool.hook("execute.before", (event) => {
      event.input = FileProtection.prepare(event.tool, event.input);
    });
  },
});
