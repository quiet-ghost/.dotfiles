import { expect, it } from "vitest";
import { Caveman } from "../lib/caveman";

it("enables ultra by default for server-side requests", () => {
  expect(Caveman.instructions(Caveman.initial)).toContain("Intensity ultra");
});
it.each(Caveman.levels)("supports %s", (level) => {
  expect(Caveman.parse(level)).toEqual({ kind: "enabled", level });
});
it("turns off injection", () => {
  expect(Caveman.instructions({ kind: "disabled" })).toBe("");
});
it("preserves safety exceptions", () => {
  expect(Caveman.instructions(Caveman.initial)).toContain(
    "irreversible confirmations",
  );
});
it("rejects invalid persisted state", () => {
  expect(
    Caveman.Mode.safeParse({ kind: "enabled", level: "invalid" }).success,
  ).toBe(false);
});
