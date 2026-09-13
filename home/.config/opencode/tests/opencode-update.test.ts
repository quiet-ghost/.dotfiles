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
if [[ $1 == use && $OC_UPDATE_TEST_FAIL == 1 ]]; then exit 17; fi
if [[ $1 == exec ]]; then shift 3; exec "$@"; fi
`,
    opencode: `#!/bin/bash
printf 'opencode %s\\n' "$*" >> "$OC_UPDATE_TEST_ROOT/trace"
if [[ $1 == --version ]]; then
  if [[ $OC_UPDATE_TEST_MISMATCH == 1 ]]; then echo 'opencode vwrong'; else echo 'opencode v2.0.2'; fi
fi
`,
    node: "#!/bin/bash\necho 2.0.2\n",
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

it("tracks stable and updates plugins after verifying the installed CLI", () => {
  const result = runUpdate();
  expect(result.status).toBe(0);
  expect(result.trace).toMatch(
    /^mise use --global --fuzzy npm:@opencode\/cli@latest\n/,
  );
  expect(result.trace).toContain("opencode --version\nmise exec npm:@opencode/cli -- opencode plugin update\nopencode plugin update\n");
  expect(result.trace).not.toContain("service restart");
});

it("propagates installation failure without claiming success", () => {
  const result = runUpdate({ installFails: true });
  expect(result.status).toBe(17);
  expect(result.stdout).not.toContain("CLI and package plugins updated");
});

it("does not accept a mismatched platform binary", () => {
  const result = runUpdate({ mismatch: true });
  expect(result.status).toBe(1);
  expect(result.trace).not.toContain("plugin update");
  expect(result.stdout).not.toContain("CLI and package plugins updated");
});
