import { describe, expect, it } from "vitest";
import { FileProtection } from "../lib/file-protection";

describe("file protection", () => {
  it.each([".env", "/project/.env.local", "/project/.envrc"])(
    "blocks read of %s",
    (path) => {
      expect(() => FileProtection.prepare("read", { path })).toThrow("blocked");
    },
  );
  it("preserves normal reads and unrelated arguments", () => {
    expect(
      FileProtection.prepare("read", { path: "README.md", offset: 10 }),
    ).toEqual({ path: "README.md", offset: 10 });
  });
  it.each(["write", "edit"])("normalizes %s note paths", (tool) => {
    expect(
      FileProtection.prepare(tool, {
        path: "home/ghost/personal/Notes/Imports/note.md",
      }),
    ).toEqual({ path: "/home/ghost/personal/Notes/Imports/note.md" });
  });
  it("repairs known mirrored notes", () => {
    expect(
      FileProtection.prepare("write", {
        filePath:
          "/home/ghost/.local/share/opencode/secrets/home/ghost/personal/Notes/Imports/note.md",
      }),
    ).toEqual({ filePath: "/home/ghost/personal/Notes/Imports/note.md" });
  });
  it("blocks other secret-mirror writes", () => {
    expect(() =>
      FileProtection.prepare("edit", {
        path: "/home/ghost/.local/share/opencode/secrets/home/ghost/other",
      }),
    ).toThrow("secrets mirror");
  });
  it("repairs patch destinations without changing contents", () => {
    const patchText =
      "*** Begin Patch\n*** Add File: home/ghost/personal/Notes/Imports/note.md\n+home/ghost/personal/Notes/Imports\n*** End Patch";
    expect(FileProtection.prepare("patch", { patchText })).toEqual({
      patchText: patchText.replace("Add File: home/", "Add File: /home/"),
    });
  });
  it("blocks secret-mirror patch moves before execution", () => {
    expect(() =>
      FileProtection.prepare("patch", {
        patchText:
          "*** Move to: /home/ghost/.local/share/opencode/secrets/home/ghost/other",
      }),
    ).toThrow("secrets mirror");
  });
});
