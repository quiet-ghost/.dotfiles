import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var hosts: []
  property var history: []
  property var activeConnections: []
  property string error: ""

  readonly property string previousHost: history.length > 0 ? String(history[0]) : ""

  function refresh() {
    if (snapshotProcess.running) return
    snapshotProcess.command = ["omarchy-ssh-panel", "snapshot"]
    snapshotProcess.running = true
  }

  function connect(alias) {
    var host = String(alias || "")
    if (host === "") return false
    Quickshell.execDetached(["xdg-terminal-exec", "-e", "omarchy-ssh-panel", "connect", host])
    delayedRefresh.restart()
    return true
  }

  function applySnapshot(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      hosts = Array.isArray(data.hosts) ? data.hosts : []
      history = Array.isArray(data.history) ? data.history : []
      activeConnections = Array.isArray(data.active) ? data.active : []
      error = ""
    } catch (e) {
      error = "SSH host data could not be read"
    }
  }

  Timer {
    interval: 5000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer { id: delayedRefresh; interval: 1200; onTriggered: root.refresh() }

  Process {
    id: snapshotProcess
    command: []
    stdout: StdioCollector { id: snapshotOutput; waitForEnd: true }
    stderr: StdioCollector { id: snapshotError; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) root.applySnapshot(snapshotOutput.text)
      else root.error = String(snapshotError.text || "SSH snapshot failed").trim()
    }
  }

  IpcHandler {
    target: "local.ssh"
    function connect(host: string): string { return root.connect(host) ? "ok" : "invalid host" }
    function previous(): string { return root.previousHost !== "" && root.connect(root.previousHost) ? "ok" : "no history" }
    function refresh(): string { root.refresh(); return "ok" }
    function status(): string { return String(root.activeConnections.length) }
  }
}
