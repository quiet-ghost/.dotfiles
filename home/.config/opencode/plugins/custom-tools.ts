import { Plugin } from "@opencode-ai/plugin";
import { registerAstGrep } from "../lib/ast-grep";
import { registerYouTube } from "../lib/youtube";

export default Plugin.define({
  id: "custom-tools",
  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      registerAstGrep(editor, ctx.location.directory);
      registerYouTube(editor);
    });
  },
});
