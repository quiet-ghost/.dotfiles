import { existsSync, readFileSync, readdirSync } from "node:fs";
import { basename, dirname, join, relative, resolve } from "node:path";
import { expect, it } from "vitest";

const configDirectory = resolve(import.meta.dirname, "..");
const skillsDirectory = resolve(configDirectory, "../../.agents/skills");

function readMarkdownFiles(directory: string): { path: string; text: string }[] {
  if (!existsSync(directory)) return [];

  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return readMarkdownFiles(path);
    return entry.isFile() && entry.name.endsWith(".md")
      ? [{ path, text: readFileSync(path, "utf8") }]
      : [];
  });
}

const commands = ["command", "commands"].flatMap((directory) =>
  readMarkdownFiles(join(configDirectory, directory)),
);
const agentDocuments = readMarkdownFiles(join(skillsDirectory, "build-agent"));
const authoringDocuments = [
  ...agentDocuments,
  ...readMarkdownFiles(join(skillsDirectory, "build-skill")),
];

it("routes command skill calls through exact V2 IDs", () => {
  const skillIds = new Set(
    readdirSync(skillsDirectory).filter((id) =>
      existsSync(join(skillsDirectory, id, "SKILL.md")),
    ),
  );
  // Omarchy supplies this skill outside the Stow package.
  skillIds.add("omarchy");

  const calls = commands.flatMap(({ path, text }) =>
    [...text.matchAll(/\bskill\(\{\s*(\w+):\s*['"]([^'"]+)['"]/g)].map(
      (match) => ({ path, field: match[1], id: match[2] ?? "" }),
    ),
  );

  expect(calls.length).toBeGreaterThan(0);
  for (const call of calls) {
    expect(call.field, call.path).toBe("id");
    expect(
      skillIds.has(call.id),
      `${call.path}: unknown skill ${call.id}`,
    ).toBe(true);
  }
});

it("routes command agent references to built-in or repository agents", () => {
  const agentIds = new Set(["build", "plan", "general", "explore"]);
  for (const directory of ["agent", "agents"]) {
    const root = join(configDirectory, directory);
    for (const { path } of readMarkdownFiles(root)) {
      agentIds.add(relative(root, path).replace(/\.md$/, ""));
    }
  }

  for (const { path, text } of commands) {
    const references = [
      ...text.matchAll(/@([a-z][a-z0-9-]*(?:\/[a-z][a-z0-9-]*)*)(?=\s+subagents?\b)/g),
      ...text.matchAll(/^agent:\s*([a-z][a-z0-9-]*)\s*$/gm),
    ];
    for (const match of references) {
      const id = match[1] ?? "";
      expect(agentIds.has(id), `${path}: unknown agent ${id}`).toBe(true);
    }
  }
});

it("teaches native V2 agent fields and preferred definition paths", () => {
  const retiredFields =
    /^(?:name|permission|tools|temperature|top_p|disable|maxSteps|variant|prompt):/m;
  let examples = 0;

  for (const { path, text } of agentDocuments) {
    for (const match of text.matchAll(/^```[^\n]*\n([\s\S]*?)^```/gm)) {
      const example = match[1] ?? "";
      expect(example, path).not.toMatch(/\.opencode\/agent\//);
      if (!/^(?:mode|permissions?|tools):/m.test(example)) continue;

      examples += 1;
      expect(example, path).not.toMatch(retiredFields);
      if (/^permissions:/m.test(example)) {
        expect(example, path).toMatch(/^permissions:\n\s+- action:/m);
      }
    }
  }

  expect(examples).toBeGreaterThan(0);
  for (const { path, text } of authoringDocuments) {
    expect(text, path).not.toMatch(/https:\/\/opencode\.ai\/docs\//);
  }
});

it("keeps authoring references linked to existing bundled files", () => {
  for (const { path, text } of authoringDocuments) {
    const prose = text.replace(/^```[^\n]*\n[\s\S]*?^```/gm, "");
    for (const match of prose.matchAll(/\]\(([^)]+)\)/g)) {
      const target = (match[1] ?? "").split("#")[0] ?? "";
      if (!target || /^[a-z]+:|^\//i.test(target)) continue;
      expect(
        existsSync(resolve(dirname(path), target)),
        `${basename(path)}: missing reference ${target}`,
      ).toBe(true);
    }
  }
});
