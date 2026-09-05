import { expect, it } from "vitest";
import { HerdrState } from "../lib/herdr-state";

const idle = {
  status: "idle",
  pending: false,
  blocked: false,
  failed: false,
} as const;
it("reports idle sessions", () =>
  expect(HerdrState.state([idle])).toBe("idle"));
it("reports a running child as working", () =>
  expect(HerdrState.state([idle, { ...idle, status: "running" }])).toBe(
    "working",
  ));
it("prioritizes a blocked child over a running root", () =>
  expect(
    HerdrState.state([
      { ...idle, status: "running" },
      { ...idle, blocked: true },
    ]),
  ).toBe("blocked"));
it("reports queued work", () =>
  expect(HerdrState.state([{ ...idle, pending: true }])).toBe("working"));
it("reports failure", () =>
  expect(HerdrState.state([{ ...idle, failed: true }])).toBe("blocked"));
