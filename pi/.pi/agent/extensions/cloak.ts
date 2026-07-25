import { readFileSync } from "node:fs";
import { join } from "node:path";

import {
  getAgentDir,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

interface CloakConfig {
  enabled: boolean;
  cloakCharacter: string;
}

const defaultConfig: CloakConfig = {
  enabled: true,
  cloakCharacter: "*",
};

function loadConfig(): CloakConfig {
  try {
    const raw: unknown = JSON.parse(
      readFileSync(join(getAgentDir(), "cloak.json"), "utf8"),
    );
    if (typeof raw !== "object" || raw === null) return defaultConfig;
    const enabled = "enabled" in raw && typeof raw.enabled === "boolean" ? raw.enabled : true;
    const cloakCharacter =
      "cloakCharacter" in raw && typeof raw.cloakCharacter === "string"
        ? raw.cloakCharacter.slice(0, 1) || "*"
        : "*";
    return { enabled, cloakCharacter };
  } catch {
    return defaultConfig;
  }
}

function redact(text: string, path: string, character: string): string {
  const mask = character.repeat(12);
  let output = text.replace(
    /(\"(?:token|access|refresh|accessToken|refreshToken|apiKey|secret|password|clientSecret|idToken|sessionToken|authorization)\"\s*:\s*\")[^\"]+/gi,
    `$1${mask}`,
  );
  if (/(?:^|\/)(?:\.env[^/]*|[^/]*\.vars[^/]*)$/i.test(path)) {
    output = output.replace(/^(\s*[A-Za-z_][A-Za-z0-9_]*\s*=).+$/gm, `$1${mask}`);
  }
  if (path.endsWith("config.toml")) {
    output = output.replace(/^(\s*(?:token|api_key|secret|password)\s*=\s*).+$/gim, `$1\"${mask}\"`);
  }
  return output;
}

export default function cloak(pi: ExtensionAPI): void {
  const config = loadConfig();
  pi.on("tool_result", (event) => {
    if (!config.enabled || event.toolName !== "read") return;
    const path = typeof event.input.path === "string" ? event.input.path : "";
    if (!path) return;

    return {
      content: event.content.map((part) =>
        part.type === "text"
          ? { ...part, text: redact(part.text, path, config.cloakCharacter) }
          : part,
      ),
    };
  });
}
