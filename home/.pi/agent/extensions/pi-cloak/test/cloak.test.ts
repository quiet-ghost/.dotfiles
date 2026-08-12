import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { cloakText, loadState } from "../index.ts";

async function withDefaultState(
  run: (state: ReturnType<typeof loadState>, cwd: string) => void,
): Promise<void> {
  const cwd = await mkdtemp(join(tmpdir(), "pi-cloak-"));
  const configPath = join(cwd, "cloak.json");

  try {
    await writeFile(
      configPath,
      JSON.stringify({ enabled: true, cloakCharacter: "*" }),
      "utf8",
    );
    run(loadState(configPath), cwd);
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
}

test("default rules mask common JSON credential fields", async () => {
  await withDefaultState((state, cwd) => {
    const input = '{"apiKey":"super-secret-value","name":"visible"}';
    const output = cloakText(input, join(cwd, "auth.json"), cwd, state);

    assert.doesNotMatch(output, /super-secret-value/);
    assert.match(output, /"apiKey":"\*+"/);
    assert.match(output, /"name":"visible"/);
  });
});

test("default rules preserve dotenv keys while masking values", async () => {
  await withDefaultState((state, cwd) => {
    const output = cloakText(
      "API_TOKEN=super-secret-value\nSAFE=also-secret",
      join(cwd, ".env.local"),
      cwd,
      state,
    );

    assert.doesNotMatch(output, /super-secret-value|also-secret/);
    assert.match(output, /^API_TOKEN=\*+$/m);
    assert.match(output, /^SAFE=\*+$/m);
  });
});

test("default rules mask config.toml secrets without changing normal fields", async () => {
  await withDefaultState((state, cwd) => {
    const output = cloakText(
      'token = "super-secret-value"\ntheme = "rose-pine"',
      join(cwd, "config.toml"),
      cwd,
      state,
    );

    assert.doesNotMatch(output, /super-secret-value/);
    assert.match(output, /^token = \*+$/m);
    assert.match(output, /^theme = "rose-pine"$/m);
  });
});
