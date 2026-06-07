/** @jsxImportSource @opentui/solid */
import type {
  TuiPlugin,
  TuiPluginApi,
  TuiPluginModule,
  TuiSlotPlugin,
} from "@opencode-ai/plugin/tui";

const LEVELS = [
  "lite",
  "full",
  "ultra",
  "wenyan-lite",
  "wenyan-full",
  "wenyan-ultra",
] as const;

type Level = (typeof LEVELS)[number];

type Mode =
  | { kind: "enabled"; level: Level }
  | { kind: "disabled" };

type Config = {
  keybind: string;
  showPromptPill: boolean;
};

const DEFAULT_CONFIG: Config = {
  keybind: "<leader>v",
  showPromptPill: true,
};

function isLevel(value: string): value is Level {
  return LEVELS.some((level) => level === value);
}

function parseConfig(options: Record<string, unknown> | undefined): Config {
  return {
    keybind: typeof options?.keybind === "string" ? options.keybind : DEFAULT_CONFIG.keybind,
    showPromptPill:
      typeof options?.showPromptPill === "boolean"
        ? options.showPromptPill
        : DEFAULT_CONFIG.showPromptPill,
  };
}

function parseMode(input: string): Mode | undefined {
  const [raw] = input.trim().toLowerCase().split(/\s+/);
  if (!raw || raw === "on") return { kind: "enabled", level: "ultra" };
  if (raw === "off" || raw === "stop" || raw === "normal") return { kind: "disabled" };
  if (isLevel(raw)) return { kind: "enabled", level: raw };
  return undefined;
}

function modeKey(sessionID: string): string {
  return `caveman.mode.${sessionID}`;
}

function defaultMode(): Mode {
  return { kind: "enabled", level: "ultra" };
}

function readMode(api: TuiPluginApi, sessionID: string): Mode {
  const stored = api.kv.get<Mode | undefined>(modeKey(sessionID), undefined);
  if (stored?.kind === "disabled") return stored;
  if (stored?.kind === "enabled" && isLevel(stored.level)) return stored;
  return defaultMode();
}

function writeMode(api: TuiPluginApi, sessionID: string, mode: Mode): void {
  api.kv.set(modeKey(sessionID), mode);
}

function label(mode: Mode): string {
  return mode.kind === "enabled" ? mode.level : "off";
}

function currentSessionID(api: TuiPluginApi): string | undefined {
  const route = api.route.current;
  if (route.name !== "session") return undefined;
  const sessionID = route.params?.sessionID;
  return typeof sessionID === "string" ? sessionID : undefined;
}

async function setMode(api: TuiPluginApi, sessionID: string, mode: Mode): Promise<void> {
  writeMode(api, sessionID, mode);
  const argument = mode.kind === "enabled" ? mode.level : "off";

  await api.client.session.command(
    {
      sessionID,
      directory: api.state.path.directory,
      command: "caveman",
      arguments: argument,
    },
    { throwOnError: true },
  );
}

function openSelector(api: TuiPluginApi): void {
  const sessionID = currentSessionID(api);
  if (!sessionID) {
    api.ui.toast({
      variant: "warning",
      title: "Caveman",
      message: "Open a session before switching caveman mode.",
      duration: 2500,
    });
    return;
  }

  const DialogSelect = api.ui.DialogSelect;
  const current = label(readMode(api, sessionID));
  api.ui.dialog.setSize("medium");
  api.ui.dialog.replace(() => (
    <DialogSelect
      title="Caveman mode"
      current={current}
      options={[
        { title: "full", value: "full", description: "Drop articles, fragments OK" },
        { title: "lite", value: "lite", description: "Tight professional sentences" },
        { title: "ultra", value: "ultra", description: "Maximum English compression" },
        { title: "wenyan-lite", value: "wenyan-lite", description: "Semi-classical Chinese" },
        { title: "wenyan-full", value: "wenyan-full", description: "Classical terse Chinese" },
        { title: "wenyan-ultra", value: "wenyan-ultra", description: "Extreme classical compression" },
        { title: "off", value: "off", description: "Normal response style" },
      ]}
      onSelect={(item) => {
        const next = parseMode(String(item.value));
        if (!next) return;

        api.ui.dialog.clear();
        void setMode(api, sessionID, next)
          .then(() => undefined)
          .catch((error) => {
            api.ui.toast({
              variant: "error",
              title: "Caveman",
              message: error instanceof Error ? error.message : "Failed to switch mode",
              duration: 3000,
            });
          });
      }}
    />
  ));
}

function registerCommand(api: TuiPluginApi, config: Config): void {
  api.keymap.registerLayer({
    mode: "base",
    commands: [
      {
        name: "caveman.select",
        title: "Caveman mode",
        category: "Prompt",
        namespace: "palette",
        slashName: "caveman-mode",
        run() {
          openSelector(api);
        },
      },
    ],
    bindings: [{ key: config.keybind, cmd: "caveman.select", desc: "Caveman mode" }],
  });
}

function registerSlots(api: TuiPluginApi, config: Config): void {
  if (!config.showPromptPill) return;

  const slots: TuiSlotPlugin = {
    slots: {
      session_prompt_right(ctx, value) {
        const mode = readMode(api, value.session_id);
        const muted = ctx.theme.current.textMuted;
        const accent = mode.kind === "enabled" ? ctx.theme.current.warning : ctx.theme.current.textMuted;

        return (
          <text fg={muted}>
            caveman <span style={{ fg: accent }}>{label(mode)}</span>
          </text>
        );
      },
    },
  };

  api.slots.register(slots);
}

const tui: TuiPlugin = async (api, rawOptions) => {
  const config = parseConfig(rawOptions);

  registerCommand(api, config);
  registerSlots(api, config);

  api.event.on("command.executed", (event) => {
    if (event.properties.name !== "caveman") return;

    const mode = parseMode(event.properties.arguments);
    if (!mode) return;

    writeMode(api, event.properties.sessionID, mode);
  });
};

const plugin: TuiPluginModule & { id: string } = {
  id: "caveman-tui",
  tui,
};

export default plugin;
