import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property bool ready: false
  property bool busy: false
  property string error: ""
  property string warning: ""
  property string selectedKey: ""
  property var devices: []
  property var selected: ({})
  property var savedColors: []
  property var favoriteColors: []
  property var whites: [2700, 3000, 3500, 4000, 5000, 6500]
  property var pendingCommand: []

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string cliPath: home + "/.local/bin/govee-lights-cli"
  readonly property bool powerOn: selected && selected.powerOn === true
  readonly property bool online: selected && selected.online === true
  readonly property string deviceName: selected && selected.name ? selected.name : "Govee"
  readonly property int brightness: selected && selected.brightness !== undefined && selected.brightness !== null
    ? Number(selected.brightness)
    : 0
  readonly property string colorHex: selected && selected.colorHex ? selected.colorHex : ""
  readonly property var scenes: selected && selected.scenes ? selected.scenes : []

  function cli(args) {
    var command = [root.cliPath]
    for (var i = 0; i < args.length; i++) command.push(String(args[i]))
    return command
  }

  function applyPayload(raw) {
    try {
      var parsed = JSON.parse(String(raw || "{}"))
      if (parsed.ok !== true) {
        root.error = String(parsed.error || "Govee command failed")
        return
      }

      if (parsed.devices) root.devices = parsed.devices
      if (parsed.selected) {
        root.selected = parsed.selected
        root.selectedKey = String(parsed.selected.key || parsed.selectedKey || "")
      } else if (parsed.selectedKey) {
        root.selectedKey = String(parsed.selectedKey)
      }
      if (parsed.colors) {
        root.savedColors = parsed.colors.saved || []
        root.favoriteColors = parsed.colors.favorites || []
      }
      if (parsed.whites) root.whites = parsed.whites
      root.warning = parsed.warning ? String(parsed.warning) : ""
      root.error = ""
      root.ready = true
    } catch (e) {
      root.error = "Govee response could not be read"
    }
  }

  function refresh() {
    if (statusProcess.running) return false
    statusProcess.command = root.cli(["status"])
    statusProcess.running = true
    return true
  }

  function run(args) {
    if (actionProcess.running) {
      root.pendingCommand = args
      return false
    }
    root.busy = true
    root.error = ""
    actionProcess.command = root.cli(args)
    actionProcess.running = true
    return true
  }

  function selectDevice(key) {
    return run(["select", key])
  }

  function togglePower() {
    return run(["power", "toggle"])
  }

  function setPower(on) {
    return run(["power", on ? "on" : "off"])
  }

  function setBrightness(value) {
    return run(["brightness", String(Math.round(value))])
  }

  function setColor(hex) {
    return run(["color", hex])
  }

  function setKelvin(value) {
    return run(["kelvin", String(Math.round(value))])
  }

  function setScene(title, source) {
    var args = ["scene", title]
    if (source) args.push(source)
    return run(args)
  }

  function saveFavorite(hex, name) {
    var args = ["favorite", hex]
    if (name) args.push(name)
    return run(args)
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess
    command: []
    stdout: StdioCollector { id: statusOutput; waitForEnd: true }
    stderr: StdioCollector { id: statusError; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) root.applyPayload(statusOutput.text)
      else root.error = String(statusError.text || "Could not read Govee status").trim()
    }
  }

  Process {
    id: actionProcess
    command: []
    stdout: StdioCollector { id: actionOutput; waitForEnd: true }
    stderr: StdioCollector { id: actionError; waitForEnd: true }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode === 0) root.applyPayload(actionOutput.text)
      else root.error = String(actionError.text || "Govee command failed").trim()
      if (root.pendingCommand.length > 0) {
        var next = root.pendingCommand
        root.pendingCommand = []
        root.run(next)
      } else {
        root.refresh()
      }
    }
  }

  IpcHandler {
    target: "ghost.govee"
    function refresh(): string { return root.refresh() ? "ok" : "busy" }
    function power(): string { return root.togglePower() ? "ok" : "busy" }
    function status(): string { return root.powerOn ? "on" : "off" }
  }
}
