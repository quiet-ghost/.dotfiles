import {
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { expect, it } from "vitest";

const updater = resolve(
  import.meta.dirname,
  "../../../.local/bin/opencode-update",
);

function runUpdate(
  options: { installFails?: boolean; mismatch?: boolean } = {},
) {
  const root = mkdtempSync(join(tmpdir(), "opencode-update-test-"));
  const bin = join(root, "bin");
  mkdirSync(bin);
  const scripts = {
    mise: `#!/bin/bash
printf 'mise %s\\n' "$*" >> "$OC_UPDATE_TEST_ROOT/trace"
if [[ $1 == where ]]; then printf '%s\\n' "$OC_UPDATE_TEST_ROOT/install"; fi
if [[ $1 == install && $OC_UPDATE_TEST_FAIL == 1 ]]; then exit 17; fi
`,
    opencode2: `#!/bin/bash
printf 'opencode2 %s\\n' "$*" >> "$OC_UPDATE_TEST_ROOT/trace"
if [[ $1 == --version ]]; then
  if [[ $OC_UPDATE_TEST_MISMATCH == 1 ]]; then echo 'opencode2 vwrong'; else echo 'opencode2 v0.0.0-beta-test'; fi
fi
`,
    node: "#!/bin/bash\necho 0.0.0-beta-test\n",
    npm: "#!/bin/bash\necho 'npm rejected mismatched binary repair' >> \"$OC_UPDATE_TEST_ROOT/trace\"\nexit 19\n",
  };
  try {
    for (const [name, script] of Object.entries(scripts)) {
      writeFileSync(join(bin, name), script, { mode: 0o755 });
    }
    const result = spawnSync("bash", [updater], {
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${bin}:${process.env.PATH ?? "/usr/bin"}`,
        OC_UPDATE_TEST_ROOT: root,
        OC_UPDATE_TEST_FAIL: options.installFails ? "1" : "0",
        OC_UPDATE_TEST_MISMATCH: options.mismatch ? "1" : "0",
        TMPDIR: root,
      },
    });
    return {
      status: result.status,
      trace: readFileSync(join(root, "trace"), "utf8"),
      stdout: result.stdout,
    };
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

it("forces a beta refresh and updates plugins before replacing the CLI", () => {
  const result = runUpdate();
  expect(result.status).toBe(0);
  expect(result.trace).toMatch(
    /^opencode2 plugin update\nmise install -f npm:@opencode-ai\/cli@beta\n/,
  );
  expect(result.trace).not.toContain("service restart");
});

it("propagates installation failure without claiming success", () => {
  const result = runUpdate({ installFails: true });
  expect(result.status).toBe(17);
  expect(result.stdout).not.toContain("CLI and package plugins updated");
});

it("does not accept a mismatched platform binary", () => {
  const result = runUpdate({ mismatch: true });
  expect(result.status).toBe(19);
  expect(result.trace).toContain("npm rejected mismatched binary repair");
  expect(result.stdout).not.toContain("CLI and package plugins updated");
});
