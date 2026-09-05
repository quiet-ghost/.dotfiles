import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import vm from "node:vm"

const source = await readFile(new URL("../Model.js", import.meta.url), "utf8")
const model = {}
vm.createContext(model)
vm.runInContext(source, model)

assert.equal(model.appForNotification("Slack").id, "slack")
assert.equal(model.appForNotification("Signal Desktop").id, "signal")
assert.equal(model.appForNotification("Vesktop").id, "discord")
assert.equal(model.appForNotification("NotDiscord"), null)

const notifications = model.chatNotifications([
  { app: "Signal", summary: "Older", timestamp: 100 },
  { app: "Slack", summary: "Newer", timestamp: 200 },
  { app: "NotDiscord", summary: "Ignore", timestamp: 300 },
])

assert.equal(notifications.length, 2)
assert.equal(notifications[0].summary, "Newer")
assert.equal(notifications[1].summary, "Older")

console.log("model: ok")
