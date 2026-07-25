import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const messages = [
  "Combobulating...",
  "Consulting the void...",
  "Herding pointers...",
  "Negotiating with entropy...",
  "Noodling...",
  "Reticulating splines...",
  "Spelunking...",
  "Tinkering...",
  "Tokenmaxxing...",
  "Whispering to the bits...",
] as const;

export default function whimsical(pi: ExtensionAPI): void {
  pi.on("turn_start", (_event, ctx) => {
    const index = Math.floor(Math.random() * messages.length);
    ctx.ui.setWorkingMessage(messages[index] ?? "Working...");
  });
  pi.on("turn_end", (_event, ctx) => {
    ctx.ui.setWorkingMessage();
  });
}
